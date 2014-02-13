{
    Wrapper for video mode routines (text and graphics)
}
unit AdT2vid;
{$PACKRECORDS 1}
interface

procedure vid_Init;
procedure vid_Deinit;
procedure vid_SetVideoMode(do_delay: Boolean);
procedure vid_SetRGBPalette(var palette);
procedure vid_FadeOut;
procedure vid_TriggerEmergencyPalette(emergency: Boolean);

implementation

uses
  CRT,
  SDL,SDL_Video,SDL_Timer,SDL__rwops,
  AdT2vscr,AdT2unit,AdT2ext2,DialogIO,TxtScrIO;

{$i adt2icon.inc}
var
  screen: PSDL_Surface;

procedure vid_Init;
begin
  SDL_Init(SDL_INIT_VIDEO or SDL_INIT_TIMER or SDL_INIT_AUDIO);
end;

procedure vid_Deinit;
begin
  SDL_FreeSurface(screen);
  SDL_Quit;
end;

var
  rgb_color_alt: array[0..15] of tRGB;

procedure vid_SetRGBPalette(var palette);
begin
  SDL_SetPalette(screen,SDL_PHYSPAL,SDL_ColorArray(palette),0,16);
end;

procedure vid_EmulateScreen;

const
  frame_start: Longint = 0;
  frame_end: Longint = 0;
  actual_frame_end: Longint = 0;

begin
  If (tracing = TRUE) then trace_update_proc;
  If (Addr(mn_environment.ext_proc_rt) <> NIL) then mn_environment.ext_proc_rt
  else update_without_trace;

  // do actual flip
  emulate_screen_all;
  SDL_Flip(screen);

  If (sdl_delay_ms = 0) then
    begin // keep framerate 50 fps
      actual_frame_end := SDL_GetTicks;
      frame_end := frame_start + (1000 div 50);
      // always sleep at least 10 msec
      if (actual_frame_end + 10 > frame_end) then frame_end := actual_frame_end + 10;
      SDL_Delay(frame_end - actual_frame_end);
      frame_start := SDL_GetTicks;
    end
  else
    SDL_Delay(sdl_delay_ms); // or do constant delay
end;

procedure vid_SetVideoMode(do_delay: Boolean);

var
  icon: pSDL_Surface;
  rwop: pSDL_RWops;

begin
  FB_xres := SCREEN_RES_x;
  FB_yres := SCREEN_RES_y;
  FB_rows := hard_MaxLn;

  If do_delay then SDL_Delay(1000);
  screen := SDL_SetVideoMode(FB_xres,FB_yres,8,SDL_SWSURFACE);
  If (screen = NIL) then
    begin
      WriteLn('SDL: Couldn''t initialize video mode');
      HALT(1);
    end;

  vid_SetRGBPalette(Addr(rgb_color)^);
  Move(rgb_color,rgb_color_alt,SizeOf(rgb_color));
  emulate_screen := vid_EmulateScreen;
  _FrameBuffer := screen^.pixels;
  rwop := SDL_RWFromMem(adt2_icon_bitmap,SizeOf(adt2_icon_bitmap));
  icon := SDL_LoadBMP_RW(rwop,TRUE);
  SDL_WM_SetIcon(icon,NIL);
  SDL_WM_SetCaption('/|DLiB TR/|CK3R ][ SDL',NIL);
end;

procedure vid_FadeOut;

var
  idx: Byte;

function min0(val: Longint): Longint;
begin
  If (val <= 0) then min0 := 0
  else min0 := val;
end;

begin
  For idx := 1 to 15 do
    begin
      rgb_color_alt[idx].r := min0(rgb_color_alt[idx].r-1);
      rgb_color_alt[idx].g := min0(rgb_color_alt[idx].g-1);
      rgb_color_alt[idx].b := min0(rgb_color_alt[idx].b-1);
    end;
  SDL_SetPalette(screen,SDL_PHYSPAL,SDL_ColorArray(Addr(rgb_color_alt)^),0,16);
end;

procedure vid_TriggerEmergencyPalette(emergency: Boolean);

var
  idx: Byte;
  
begin
  EXIT; // this crashes under linux. HACK! TODO!
  If emergency then
    begin        
      For idx := 0 to 15 do
        rgb_color_alt[idx].r := $0ff-rgb_color[idx].r;
    end
  else Move(rgb_color,rgb_color_alt,SizeOf(rgb_color));
  SDL_SetPalette(screen,SDL_PHYSPAL,SDL_ColorArray(Addr(rgb_color_alt)^),0,16);
end;

end.
