unit BFParser;

interface

uses
    SysUtils
  , BFStackIntf
  , Generics.Collections
  ;

type
    IBFProgram = Interface ['{56E9D1C7-756B-4C96-9F7F-A66FE2A5BE06}']
      function Run(Input: IBFInput): IBFProgram;
      function Output: String;
    End;

    TBFProgram = Class(TInterfacedObject, IBFProgram)
    private
      FSource: String;
      FOutput: String;
      FOutputStack: IBFStack;
      FLoops: TList<LongWord>;
      FIndex: LongWord;
      function StartLoop: Boolean;
      function StopLoop: Boolean;
      function FindLoopStart: Integer;
      function FindLoopStop: Integer;
    public
      constructor Create(Source: String);
      destructor Destroy; Override;
      class function New(Source: String): IBFProgram;
      class function NewFromFile(SourceFile: TFileName): IBFProgram;
      function Run(Input: IBFInput): IBFProgram;
      function Output: String;
    End;

implementation

uses
    Classes
  , BFStackImpl
  ;

{ TBFProgram }

constructor TBFProgram.Create(Source: String);
begin
     FLoops       := TList<LongWord>.Create;
     FSource      := Source;
     FOutputStack := TBFStack.New;
end;

destructor TBFProgram.Destroy;
begin
     FLoops.Free;
     inherited;
end;

function TBFProgram.FindLoopStart: Integer;
var
   i, Count: Integer;
begin
     Result := -1;
     Count  := 0;
     for i := FIndex-1 downto 1 do
         begin
              if FSource[i]=']'
                 then Inc(Count);
              if (FSource[i]='[') and (Count = 0)
                 then begin
                           Result := i;
                           Break;
                      end;
         end;
     if Result = -1
        then raise EInvalidOperation.Create(Format('Invalid Operation: Loop at %d ends without starting.', [FIndex]));
end;

function TBFProgram.FindLoopStop: Integer;
var
   i, Count: Integer;
begin
     Result := -1;
     Count  := 0;
     for i := FIndex+1 to Length(FSource) do
         begin
              if FSource[i]='['
                 then Inc(Count);
              if (FSource[i]=']') and (Count = 0)
                 then begin
                           Result := i;
                           Break;
                      end;
         end;
     if Result = -1
        then raise EInvalidOperation.Create(Format('Invalid Operation: Loop at %d has no end.', [FIndex]));
end;

class function TBFProgram.New(Source: String): IBFProgram;
begin
     Result := Create(Source);
end;

class function TBFProgram.NewFromFile(SourceFile: TFileName): IBFProgram;
var
   Lst: TStringList;
begin
     if not FileExists(SourceFile)
        then raise EInOutError.Create(Format('%s file not found.', [SourceFile]));

     Lst := TStringList.Create;
     try
        Lst.LoadFromFile(SourceFile);
        Result := Create(Lst.Text);
     finally
        Lst.Free;
     end;
end;

function TBFProgram.Output: String;
begin
     Result := FOutput;
end;

function TBFProgram.Run(Input: IBFInput): IBFProgram;
begin
     Result     := Self;
     FIndex     := 1;
     while FIndex <= Length(FSource) do
           with FOutputStack do
                begin
                     case FSource[FIndex] of
                          '>': MoveRight;
                          '<': MoveLeft;
                          '+': Cell.Add;
                          '-': Cell.Sub;
                          '.': FOutput := FOutput + Chr(Cell.Value);
                          ',': Cell.Define(Input.Value);
                          '[': if not StartLoop
                                  then FIndex := FindLoopStop-1;
                          ']': if not StopLoop
                                  then FIndex := FindLoopStart;
                     end;
                     Inc(FIndex);
                end;
end;

function TBFProgram.StartLoop: Boolean;
begin
     FLoops.Add(FIndex);
     Result := FOutputStack.Cell.Value <> 0;
end;

function TBFProgram.StopLoop: Boolean;
begin
     Result := FOutputStack.Cell.Value = 0;
     if Result
        then FLoops.Delete(FLoops.Count-1);
end;


end.
