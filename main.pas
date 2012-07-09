unit main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, StrUtils, math, ComCtrls, pngimage;

type
  TForm2 = class(TForm)
    Button1: TButton;
    ProgressBar1: TProgressBar;
    StatusBar1: TStatusBar;
    ProgressBar2: TProgressBar;
    CheckBox1: TCheckBox;
    procedure Button1Click(Sender: TObject);
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
  Form2: TForm2;

implementation

{$R *.dfm}


type
   TMap = record
      name:String;
      zoom,w,h:integer;
      xf,yf:double;
   end;
   TDataPoint = record
      t:integer;
      x,y,r:double;
   end;

const

   maps:array[1..1] of TMap = (
      //(name:'europeb';        zoom:6;  w:1920;   h:1080; xf:9.8; yf:51.3)
      (name:'berlin';         zoom:11;  w:1920;   h:1080; xf:13.404865; yf:52.52113)

      {
      (name:'world';          size:1024;  scale:1;    x:0;     y:160;   w:1024;  h:576),
      (name:'usa';            size:1024;  scale:2;    x:128;   y:256;   w:256;   h:256),
      (name:'europe';         size:1024;  scale:8;    x:435;   y:256;   w:200;   h:200),
      (name:'europec';        size:1024;  scale:16;   x:461;   y:297;   w:160;   h:90),
      (name:'germany';        size:1024;  scale:16;   x:520;   y:314;   w:42;    h:56),
      (name:'ukandirland';    size:1024;  scale:32;   x:476;   y:308;   w:48;    h:48),
      (name:'berlin';         size:1024;  scale:128;  x:548;   y:334;   w:4;     h:4),
      (name:'berlin zoomed';  size:32768; scale:16;   x:17576; y:10728; w:52;    h:40),
      (name:'ruhr';           size:1024;  scale:256;  x:529;   y:678;   w:8;     h:8),
      (name:'frankfurt';      size:1024;  scale:256;  x:532;   y:672;   w:8;     h:8)  }
   );

   blurred:Boolean = true;
   sourceFile:String = 'D:\Projekte\crowdflow\daten\consolidiert\qryResults.txt';

   maxUser = 882;
   maxEntries = 3000;

var
   //dataResult:array of word;
   dataFloat:array of Double;
   pngBackground:TPNGImage;
   user:array[0..maxUser] of record
      count: integer;
      points:array[0..maxEntries] of TDataPoint
   end;


function getString(line:String; n:integer):String;
var
   i,p1,p2:integer;
   s:String;
begin
   p1:=0;
   p2:=0;
   for i:=0 to n do begin
      p1:=p2;
      p2:=PosEx(#9,line,p1+1);
   end;
   if (p2 = 0) then p2:=Length(line)+1;
   s:=MidStr(line,p1+1,p2-p1-1);
   getString:=s;
end;

function intLin(x, x0,y0, x1,y1:double):double;
var
   v:double;
begin
   if x<=x0 then begin
      result:=y0;
      exit;
   end;
   if x>=x1 then begin
      result:=y1;
      exit;
   end;

   v:=x1-x0;
   if v>0 then begin
      v:=(x-x0)/v;
      result:=(y1-y0)*v+y0;
   end else begin
      result:=y0;
   end;
end;

function intCub(x, x0,y0, x1,y1, x2,y2, x3,y3:double):double;
var
   v,v1,v2,v3,a,b:double;
begin
   if x<=x1 then begin
      result:=y1;
      exit;
   end;
   if x>=x2 then begin
      result:=y2;
      exit;
   end;
   if x2-x1>0 then begin
      v1:=(y1-y0)/(x1-x0+0.1);
      v2:=(y2-y1)/(x2-x1+0.1);
      v3:=(y3-y2)/(x3-x2+0.1);

      if sign(v1) <> sign(v2) then v1:=0 else if abs(v2) < abs(v1) then v1:=v2;
      if sign(v2) <> sign(v3) then v2:=0 else if abs(v3) < abs(v2) then v2:=v3;

      a:=v2+v1+2*(y1-y2);
      b:=-v2-2*v1-3*y1+3*y2;
      v:=(x-x1)/(x2-x1);

      result:=((a*v+b)*v+v1)*v+y1;
   end else begin
      result:=y1;
   end;
end;

procedure renderMap(mapIndex:integer; timeIndex:integer);
const
   pi2 = 6.283185307179586476925286766559;
var
   maxx,maxy,dataSize,r,userId,xMin,yMin,xMax,yMax,x,y,xi,yi,i,c,t:integer;
   xf,yf,rf,x2f,y2f,r2f,rfmax,xr,yr,xif,yif,v,dt,a:Double;
   x0,y0,scale,t0:double;
   s:String;
   png,pngtemp:TPNGImage;
   p,pb:PByteArray;
   p0,p1,p2,p3:TDataPoint;
   LogFont:TLogFont;
begin
   scale := Power(2,maps[mapIndex].zoom+8);
   x0 := maps[mapIndex].xf;
   y0 := maps[mapIndex].yf;
   x0:=0.5+x0/360;
   y0:=0.5+ln(tan(pi/4-pi*y0/360))/(2*pi);
   maxx := maps[mapIndex].w;
   maxy := maps[mapIndex].h;

   form2.Caption:=inttostr(maxx)+'x'+inttostr(maxy);

   DecimalSeparator:='.';

   SetLength(dataFloat, maxx*maxy);

   dataSize:=maxx*maxy;
   FillChar(dataFloat[0], dataSize*sizeOf(Double), 0);

   r:=512;
   rfmax:=sqr(r/(scale));

   Form2.ProgressBar1.Max:=maxUser;

   //t0:=timeIndex*10+482340;
   t0:=timeIndex+482340+12*1440;


   for userId:=0 to maxuser do if user[userId].count>0 then begin
      for i:=0 to user[userId].count-1 do begin
         t:=i;
         if user[userId].points[i].t>=t0 then break;
      end;

      p2:=user[userId].points[t];
      if t>0 then p1:=user[userId].points[t-1] else p1:=p2;
      if t>1 then p0:=user[userId].points[t-2] else p0:=p1;
      if t<user[userId].count-1 then p3:=user[userId].points[t+1] else p3:=p2;

      xf:=intCub(t0, p0.t,p0.x, p1.t,p1.x, p2.t,p2.x, p3.t,p3.x);
      yf:=intCub(t0, p0.t,p0.y, p1.t,p1.y, p2.t,p2.y, p3.t,p3.y);
      rf:=intLin(t0, p1.t,p1.r, p2.t,p2.r);

      dt:=min(abs(t0-p1.t),abs(t0-p2.t));
      rf:=(rf+dt*10/(40074*60));

      rf:=sqr(rf);
      a:=Power(rf,0.3);

      xr:=(xf-x0)*scale+maxx/2;
      yr:=(yf-y0)*scale+maxy/2;

      x:=round(xr);
      y:=round(yr);

      xMin:=max(0,x-r);
      yMin:=max(0,y-r);
      xMax:=min(maxx-1, x+r);
      yMax:=min(maxy-1, y+r);

      for yi:=yMin to yMax do begin
         yif:=(yi-maxy/2)/scale+y0;
         for xi:=xMin to xMax do begin
            xif:=(xi-maxx/2)/scale+x0;
            v:=sqr(xf-xif)+sqr(yf-yif);
            v:=1/(v+rf)-1/rfmax;
            if v>0 then begin
               i:=yi*maxx+xi;
               dataFloat[i]:=dataFloat[i]+v*a;
            end;
         end;
      end;

      Form2.ProgressBar1.Position:=userId;
   end;

   Form2.ProgressBar1.Max:=maxuser;

   v:=(t0+60)/1440+40299;

   pngtemp:=TPngImage.Create;
   pngBackground.AssignTo(pngtemp);
   pngtemp.Canvas.Brush.Style:=bsClear;
   pngtemp.Canvas.Font.Name:='Myriad Pro';
   pngtemp.Canvas.Font.Style:=[fsBold];
   pngtemp.Canvas.Font.Color:=$FFFFFF;
   pngtemp.Canvas.Font.Size:=60;
   GetObject(pngtemp.Canvas.Font.Handle, SizeOf(TLogFont), @LogFont);
   LogFont.lfQuality := ANTIALIASED_QUALITY;
   pngtemp.Canvas.Font.Handle := CreateFontIndirect(LogFont);

   pngtemp.Canvas.TextOut(37,910,LeftStr(TimeToStr(v),5));

   pngtemp.Canvas.Font.Style:=[];
   pngtemp.Canvas.Font.Color:=$A8A8A8;
   pngtemp.Canvas.Font.Size:=29;
   GetObject(pngtemp.Canvas.Font.Handle, SizeOf(TLogFont), @LogFont);
   LogFont.lfQuality := ANTIALIASED_QUALITY;
   pngtemp.Canvas.Font.Handle := CreateFontIndirect(LogFont);

   pngtemp.Canvas.TextOut(45,1003,ReplaceStr(DateToStr(v),'.','-'));


   png:=TPNGImage.CreateBlank(COLOR_RGB, 8, maxx, maxy);
   png.CompressionLevel:=9;
   i:=0;
   dt:=1;
   for yi:=0 to maxy-1 do begin
      p:=png.Scanline[yi];
      pb:=pngtemp.Scanline[yi];
      for xi:=0 to maxx-1 do begin
         v:=dataFloat[i]/2e6;
         a:=pb[xi*3]/255;

         //color:green
         p[xi*3+0]:=round(min(1, (Power(a,1/1.8)+Power(v, 4.2)*0.10))*255);
         p[xi*3+1]:=round(min(1, (Power(a,1/1.1)+Power(v, 0.7)*1.00))*255);
         p[xi*3+2]:=round(min(1, (Power(a,1/0.5)+Power(v, 1.4)*1.00))*255);


         {
         //color:fire
         p[xi*3+0]:=round(min(1, (Power(a,1/1.8)+Power(v, 2.8)*0.8))*255);
         p[xi*3+1]:=round(min(1, (Power(a,1/0.9)+Power(v, 1.4)*1.0))*255);
         p[xi*3+2]:=round(min(1, (Power(a,1/0.8)+Power(v, 0.7)*1.2))*255);
         }

         {
         //color:sepia
         p[xi*3+0]:=round(min(1, (Power(a,1.87)+Power(v, 1)*1.44))*255);
         p[xi*3+1]:=round(min(1, (Power(a,1.07)+Power(v, 2)*1.20))*255);
         p[xi*3+2]:=round(min(1, (Power(a,0.67)+Power(v, 4)*1.00))*255);
         }

         inc(i);
      end;
   end;

   png.SaveToFile('D:\Projekte\crowdflow\resultate8\frames1\'+maps[mapIndex].name+inttostr(timeIndex)+'.png');
   png.Destroy;

   pngtemp.Destroy;

   form2.StatusBar1.SimpleText:='Fertig';
end;

procedure loadData();
var
   f:Textfile;
   s:String;
   userId,i,x,y:integer;
   lat,lon,latv,lonv,radius:Double;
   png:TPNGImage;
   p:PByteArray;
begin
   fillChar(user, sizeOf(user), 0);

   AssignFile(f, sourceFile);
   Reset(f);
   Readln(f, s);
   while not eof(f) do begin
      Readln(f, s);
      userId:=strtoint(getString(s,0));
      i:=user[userId].count;

      user[userId].points[i].t:=strtoint(getString(s,1));

      lat:=strtofloat(getString(s,2));
      lon:=strtofloat(getString(s,3));

      latv:=strtofloat(getString(s,4));
      lonv:=strtofloat(getString(s,5));

      radius:=sqrt(abs(latv)+abs(lonv)*sqr(cos(3.14159*lat/180))); // in °
      radius:=radius/(360*cos(3.14159*lat/180));

      user[userId].points[i].x:=0.5+lon/360;
      user[userId].points[i].y:=0.5+ln(tan(pi/4-pi*lat/360))/(2*pi);
      user[userId].points[i].r:=radius;

      inc(user[userId].count);
   end;
   CloseFile(f);

   pngBackground:=TPngImage.Create;
   pngBackground.LoadFromFile('D:\Projekte\crowdflow\resultate8\map-europeb.png');
end;

procedure TForm2.Button1Click(Sender: TObject);
const
   iMin=0;
   iMax=1440;
var
   i:Integer;
   t0,t1:TDateTime;
begin
   loadData();

   ProgressBar2.Max:=10000;
   ProgressBar2.Min:=iMin;
   ProgressBar2.Max:=iMax;

   t0:=now();

   for i:=iMin to iMax do begin
      if CheckBox1.Checked then exit;

      ProgressBar2.Position:=i;
      renderMap(1, i);

      t1:=now();
      t1:=t0+(iMax-iMin+1)*(t1-t0)/(i-iMin+1);
      StatusBar1.SimpleText:=TimeToStr(t1);
      application.ProcessMessages;
   end;
end;

end.
