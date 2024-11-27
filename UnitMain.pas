// 2024-2024 Turborium (c) ~ #OrganicCode
unit UnitMain;

{$MODE DELPHIUNICODE}

interface

uses
  Classes, ComCtrls, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, Math, BitmapPixels;

const
  ExpectedFps = 30;
  BitmapDefaultWidth = 240;
  BitmapDefaultHeight = 180;
  DisplayScale = 5;

  ParticleCount = 34;

  ParticleStepCount = 70 + 90;
  ParticleScale = 16;
  ParticleIterationCount = 120;
  ParticleGlowSize = 3;
  ParticleSwapDirectionRarity = 20;
  BlurIterationCount = 2400;

  ParticleRecolorRarity = 70 + 60;

  ParticleMinValue = 1;
  ParticleMaxValue = 9;
  ParticleGlowMinValue = 1;
  ParticleGlowMaxValue = 7;

  FadeRValue = 3;
  FadeGValue = 4;
  FadeBValue = 2;

type
  TParticle = record
    X, Y: Integer;
    Steps: array [0..ParticleStepCount - 1] of Integer;
    ParticleRValue: Integer;
    ParticleGValue: Integer;
    ParticleBValue: Integer;
    ParticleGlowRValue: Integer;
    ParticleGlowGValue: Integer;
    ParticleGlowBValue: Integer;
  end;

  { TFormMain }

  TFormMain = class(TForm)
    PaintBox: TPaintBox;
    Timer: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure PaintBoxPaint(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
  private
    FBitmap: TBitmap;
    FParticles: array [0..ParticleCount - 1] of TParticle;
    procedure ResetEffect();
    procedure PaintEffect(Data: TBitmapData);
  end;

var
  FormMain: TFormMain;

implementation

{$R *.lfm}

{ TFormMain }

procedure TFormMain.FormCreate(Sender: TObject);
begin
  // создаем битмап для эффекта
  FBitmap := TBitmap.Create();

  // настраиваем размер формы под дефолтные размеры
  ClientWidth := BitmapDefaultWidth * DisplayScale;
  ClientHeight := BitmapDefaultHeight * DisplayScale;

  // настраиваем таймер для fps
  Timer.Interval := 1000 div ExpectedFps;
end;

procedure TFormMain.FormDestroy(Sender: TObject);
begin
  // уничтожаем битмап
  FBitmap.Free();
end;

procedure TFormMain.FormResize(Sender: TObject);
begin
  // настраиваем размер битмапа под размер экрана, с учетом скейла
  FBitmap.SetSize(PaintBox.Width div DisplayScale, PaintBox.Height div DisplayScale);
  // сбрасываем эффект
  ResetEffect();
end;

procedure TFormMain.PaintBoxPaint(Sender: TObject);
var
  Data: TBitmapData;
begin
  // создаем Data для изменения пикселов битмапа
  Data.Map(FBitmap, TAccessMode.ReadWrite, False, clBlack);
  try
    // рисуем эффект
    PaintEffect(Data);
  finally
    // применяем изменения
    Data.Unmap();
  end;

  // рисуем битмап на экран
  PaintBox.Canvas.StretchDraw(
    TRect.Create(0, 0, (PaintBox.Width div DisplayScale) * DisplayScale, (PaintBox.Height div DisplayScale) * DisplayScale),
    FBitmap
  );
end;

procedure TFormMain.TimerTimer(Sender: TObject);
begin
  // вызываем перерисовку PaintBox
  PaintBox.Invalidate();
end;

procedure TFormMain.ResetEffect();
var
  I, J: Integer;
begin
  // заливаем черным цветом
  FBitmap.Canvas.Brush.Color := clBlack;
  FBitmap.Canvas.FillRect(0, 0, FBitmap.Width, FBitmap.Height);

  for I := 0 to High(FParticles) do
  begin
    FParticles[I].X := FBitmap.Width * ParticleScale div 2;
    FParticles[I].Y := FBitmap.Height * ParticleScale div 2;
    for J := 0 to High(FParticles[I].Steps) do
    begin
      FParticles[I].Steps[J] := -1;// ничего
    end;
    FParticles[I].ParticleRValue := RandomRange(ParticleMinValue, ParticleMaxValue);
    FParticles[I].ParticleGValue := RandomRange(ParticleMinValue, ParticleMaxValue);
    FParticles[I].ParticleBValue := RandomRange(ParticleMinValue, ParticleMaxValue);
    FParticles[I].ParticleGlowRValue := RandomRange(ParticleGlowMinValue, ParticleGlowMaxValue);
    FParticles[I].ParticleGlowGValue := RandomRange(ParticleGlowMinValue, ParticleGlowMaxValue);
    FParticles[I].ParticleGlowBValue := RandomRange(ParticleGlowMinValue, ParticleGlowMaxValue);
  end;
end;

procedure TFormMain.PaintEffect(Data: TBitmapData);

  procedure Fade();
  var
    X, Y: Integer;
    Pixel: TPixelRec;
  begin
    for Y := 0 to Data.Height - 1 do
    begin
      for X := 0 to Data.Width - 1 do
      begin
        Pixel := Data.GetPixel(X, Y);
        Pixel.R := Max(0, Pixel.R - FadeRValue);
        Pixel.G := Max(0, Pixel.G - FadeGValue);
        Pixel.B := Max(0, Pixel.B - FadeBValue);
        Data.SetPixel(X, Y, Pixel);
      end;
    end;
  end;

  procedure Draw();

    procedure PaintAndUpdateParticle(var Particle: TParticle);
    var
      Index: Integer;
      X, Y: Integer;
      I: Integer;
      Pixel: TPixelRec;
      N: Integer;
    begin
      Index := 0;
      for I := 1 to ParticleIterationCount do
      begin
        // рисуем свечение
        X := Random(ParticleGlowSize * 2 + 1) - ParticleGlowSize;
        Y := Random(ParticleGlowSize * 2 + 1) - ParticleGlowSize;
        Pixel := Data.GetPixel(Particle.X div ParticleScale + X, Particle.Y div ParticleScale + Y);
        Pixel.R := Min(255, Pixel.R + Particle.ParticleGlowRValue);
        Pixel.G := Min(255, Pixel.G + Particle.ParticleGlowGValue);
        Pixel.B := Min(255, Pixel.B + Particle.ParticleGlowBValue);
        Data.SetPixel(Particle.X div ParticleScale + X, Particle.Y div ParticleScale + Y, Pixel);

        // рисуем точку
        Pixel := Data.GetPixel(Particle.X div ParticleScale, Particle.Y div ParticleScale);
        Pixel.R := Min(255, Pixel.R + Particle.ParticleRValue);
        Pixel.G := Min(255, Pixel.G + Particle.ParticleGValue);
        Pixel.B := Min(255, Pixel.B + Particle.ParticleBValue);
        Data.SetPixel(Particle.X div ParticleScale, Particle.Y div ParticleScale, Pixel);

        // генерация неправления
        if Random(ParticleSwapDirectionRarity) = 0 then
          Particle.Steps[Random(Length(Particle.Steps))] := Random(4);

        // сдвиг
        case Particle.Steps[Index] of
          0:
          begin
            Particle.X := Particle.X + 1;
            Particle.Y := Particle.Y + 1;
          end;
          1:
          begin
            Particle.X := Particle.X - 1;
            Particle.Y := Particle.Y + 1;
          end;
          2:
          begin
            Particle.X := Particle.X + 1;
            Particle.Y := Particle.Y - 1;
          end;
          3:
          begin
            Particle.X := Particle.X - 1;
            Particle.Y := Particle.Y - 1;
          end;
        end;

        // коррекция
        if Particle.X < 0 then
        begin
          Particle.X := Data.Width * ParticleScale - 1;
        end;
        if Particle.X >= Data.Width * ParticleScale then
        begin
          Particle.X := 0;
        end;
        if Particle.Y < 0 then
        begin
          Particle.Y := Data.Height * ParticleScale - 1;
        end;
        if Particle.Y >= Data.Height * ParticleScale then
        begin
          Particle.Y := 0;
        end;

        // следующий индекс
        Index := Index + 1;
        if Index >= Length(Particle.Steps) then
        begin
          Index := 0;
        end;

        // перекраска
        if Random(ParticleRecolorRarity) = 0 then
        begin
          N := Random(ParticleCount);
          if Random(2) = 0 then
          case Random(3) of
            0: FParticles[N].ParticleRValue := EnsureRange(FParticles[N].ParticleRValue + Random(3) - 1, ParticleMinValue, ParticleMaxValue);
            1: FParticles[N].ParticleGValue := EnsureRange(FParticles[N].ParticleGValue + Random(3) - 1, ParticleMinValue, ParticleMaxValue);
            2: FParticles[N].ParticleBValue := EnsureRange(FParticles[N].ParticleBValue + Random(3) - 1, ParticleMinValue, ParticleMaxValue);
          end
          else
          case Random(3) of
            0: FParticles[N].ParticleGlowRValue := EnsureRange(FParticles[N].ParticleGlowRValue + Random(3) - 1, ParticleGlowMinValue, ParticleGlowMaxValue);
            1: FParticles[N].ParticleGlowGValue := EnsureRange(FParticles[N].ParticleGlowGValue + Random(3) - 1, ParticleGlowMinValue, ParticleGlowMaxValue);
            2: FParticles[N].ParticleGlowBValue := EnsureRange(FParticles[N].ParticleGlowBValue + Random(3) - 1, ParticleGlowMinValue, ParticleGlowMaxValue);
          end;
        end;
      end;
    end;

  var
    I: Integer;
  begin
    for I := 0 to High(FParticles) do
    begin
      PaintAndUpdateParticle(FParticles[I]);
    end;
  end;

  procedure Blur();
  var
    R, G, B: Integer;
    X, Y: Integer;
    I: Integer;
    Pixel: TPixelRec;
  begin
    for I := 1 to BlurIterationCount do
    begin
      R := 0;
      G := 0;
      B := 0;
      X := Random(Data.Width);
      Y := Random(Data.Height);
      if X >= 1 then
      begin
        Pixel := Data.GetPixel(X - 1, Y);
        R := R + Pixel.R;
        G := G + Pixel.G;
        B := B + Pixel.B;
      end;
      if X < Data.Width - 1 then
      begin
        Pixel := Data.GetPixel(X + 1, Y);
        R := R + Pixel.R;
        G := G + Pixel.G;
        B := B + Pixel.B;
      end;
      if Y >= 1 then
      begin
        Pixel := Data.GetPixel(X, Y - 1);
        R := R + Pixel.R;
        G := G + Pixel.G;
        B := B + Pixel.B;
      end;
      if Y < Data.Height - 1 then
      begin
        Pixel := Data.GetPixel(X, Y + 1);
        R := R + Pixel.R;
        G := G + Pixel.G;
        B := B + Pixel.B;
      end;
      Pixel.R := R div 4;
      Pixel.G := G div 4;
      Pixel.B := B div 4;
      Data.SetPixel(X, Y, Pixel);
    end;
  end;

begin
  Fade();
  Draw();
  Blur();
end;

end.

