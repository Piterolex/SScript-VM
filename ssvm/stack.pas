(*
 Copyright © by Patryk Wychowaniec, 2013
 All rights reserved.
*)
{$H+}
Unit Stack;

 Interface

 Type TMixedValueType = (mvNone=-1, mvBool, mvChar, mvInt, mvFloat, mvString, mvReference, mvCallstackRef);

 Type PStackElement = ^TStackElement;

      PMixedValue = ^TMixedValue;
      TMixedValue = Record
                     Typ  : TMixedValueType;
                     Value: Record
                             Bool : Boolean;
                             Char : Char;
                             Int  : Int64;
                             Float: Extended;
                             Str  : PChar;
                            End;

                     isStackval: Boolean;
                     Stackval  : PStackElement;

                     isReg   : Boolean;
                     RegIndex: uint8;
                    End;

      TStackElement = TMixedValue;

 {$IF sizeof(TMixedValue) <> 64}
  {$FATAL Size of TMixedValue structure must have exactly 64 bytes!}
 {$ENDIF}

 Const MixedValueTypeNames: Array[TMixedValueType] of String = ('none', 'bool', 'char', 'int', 'float', 'string', 'reference', 'callstack reference');

 Type PStack = ^TStack;
      TStack = Array of TStackElement;

 // ---------- //

 Operator = (P1, P2: TMixedValue): Boolean;
 Operator <> (P1, P2: TMixedValue): Boolean;
 Operator > (P1, P2: TMixedValue): Boolean;
 Operator >= (P1, P2: TMixedValue): Boolean;
 Operator < (P1, P2: TMixedValue): Boolean;
 Operator <= (P1, P2: TMixedValue): Boolean;

 // ---------- //

 Function getBool(MV: TMixedValue): Boolean; inline;
 Function getChar(MV: TMixedValue): Char; inline;
 Function getInt(MV: TMixedValue): Int64; inline;
 Function getFloat(MV: TMixedValue): Extended; inline;
 Function getString(MV: TMixedValue): PChar; inline;
 Function getReference(MV: TMixedValue): Pointer; inline;

 Function getTypeName(MV: TMixedValue): String;

 Implementation
Uses mStrings, SysUtils;

(* = *)
Operator = (P1, P2: TMixedValue): Boolean;
Begin
 Result := False;

 if (P1.Typ = mvFloat) and (P2.Typ = mvInt) { float = int } Then
  Exit(P1.Value.Float = P2.Value.Int);

 if (P1.Typ = mvInt) and (P2.Typ = mvFloat) { int = float } Then
  Exit(P1.Value.Int = P2.Value.Float);

 if (P1.Typ <> P2.Typ) Then
  Exit(False);

 Case P1.Typ of
  mvBool  : Exit(P1.Value.Bool = P2.Value.Bool);
  mvChar  : Exit(P1.Value.Char = P2.Value.Char);
  mvInt   : Exit(P1.Value.Int = P2.Value.Int);
  mvFloat : Exit(P1.Value.Float = P2.Value.Float);
  mvString: Exit(P1.Value.Str = P2.Value.Str);
 End;
End;

(* <> *)
Operator <> (P1, P2: TMixedValue): Boolean;
Begin
 Result := not (P1 = P2);
End;

(* > *)
Operator > (P1, P2: TMixedValue): Boolean;
Begin
 Result := False;

 if (P1.Typ = mvFloat) and (P2.Typ = mvInt) { float > int } Then
  Exit(P1.Value.Float > P2.Value.Int);

 if (P1.Typ = mvInt) and (P2.Typ = mvFloat) { int > float } Then
  Exit(P1.Value.Int > P2.Value.Float);

 if (P1.Typ <> P2.Typ) Then
  Exit(False);

 Case P1.Typ of
  mvBool  : Exit(P1.Value.Bool > P2.Value.Bool);
  mvChar  : Exit(P1.Value.Char > P2.Value.Char);
  mvInt   : Exit(P1.Value.Int > P2.Value.Int);
  mvFloat : Exit(P1.Value.Float > P2.Value.Float);
  mvString: Exit(P1.Value.Str > P2.Value.Str);
 End;
End;

(* >= *)
Operator >= (P1, P2: TMixedValue): Boolean;
Begin
 Result := False;

 if (P1.Typ = mvFloat) and (P2.Typ = mvInt) { float >= int } Then
  Exit(P1.Value.Float >= P2.Value.Int);

 if (P1.Typ = mvInt) and (P2.Typ = mvFloat) { int >= float } Then
  Exit(P1.Value.Int >= P2.Value.Float);

 if (P1.Typ <> P2.Typ) Then
  Exit(False);

 Case P1.Typ of
  mvBool  : Exit(P1.Value.Bool >= P2.Value.Bool);
  mvChar  : Exit(P1.Value.Char >= P2.Value.Char);
  mvInt   : Exit(P1.Value.Int >= P2.Value.Int);
  mvFloat : Exit(P1.Value.Float >= P2.Value.Float);
  mvString: Exit(P1.Value.Str >= P2.Value.Str);
 End;
End;

(* < *)
Operator < (P1, P2: TMixedValue): Boolean;
Begin
 Result := False;

 if (P1.Typ = mvFloat) and (P2.Typ = mvInt) { float < int } Then
  Exit(P1.Value.Float < P2.Value.Int);

 if (P1.Typ = mvInt) and (P2.Typ = mvFloat) { int < float } Then
  Exit(P1.Value.Int < P2.Value.Float);

 if (P1.Typ <> P2.Typ) Then
  Exit(False);

 Case P1.Typ of
  mvBool  : Exit(P1.Value.Bool < P2.Value.Bool);
  mvChar  : Exit(P1.Value.Char < P2.Value.Char);
  mvInt   : Exit(P1.Value.Int < P2.Value.Int);
  mvFloat : Exit(P1.Value.Float < P2.Value.Float);
  mvString: Exit(P1.Value.Str < P2.Value.Str);
 End;
End;

(* <= *)
Operator <= (P1, P2: TMixedValue): Boolean;
Begin
 Result := False;

 if (P1.Typ = mvFloat) and (P2.Typ = mvInt) { float <= int } Then
  Exit(P1.Value.Float <= P2.Value.Int);

 if (P1.Typ = mvInt) and (P2.Typ = mvFloat) { int <= float } Then
  Exit(P1.Value.Int <= P2.Value.Float);

 if (P1.Typ <> P2.Typ) Then
  Exit(False);

 Case P1.Typ of
  mvBool  : Exit(P1.Value.Bool <= P2.Value.Bool);
  mvChar  : Exit(P1.Value.Char <= P2.Value.Char);
  mvInt   : Exit(P1.Value.Int <= P2.Value.Int);
  mvFloat : Exit(P1.Value.Float <= P2.Value.Float);
  mvString: Exit(P1.Value.Str <= P2.Value.Str);
 End;
End;

(* getBool *)
Function getBool(MV: TMixedValue): Boolean;
Begin
 With MV do
  Case Typ of
   { bool }
   mvBool: Exit(Value.Bool);

   { int }
   mvInt: Exit(Boolean(Value.Int));
  End;

 raise Exception.Create('Invalid casting: '+MixedValueTypeNames[MV.Typ]+' -> bool');
End;

(* getChar *)
Function getChar(MV: TMixedValue): Char;
Begin
 With MV do
  Case Typ of
   { char }
   mvChar: Exit(Value.Char);

   { int }
   mvInt: Exit(Char(Value.Int));

   { string }
   mvString: Exit(Value.Str[1]);
  End;

 raise Exception.Create('Invalid casting: '+MixedValueTypeNames[MV.Typ]+' -> char');
End;

(* getInt *)
Function getInt(MV: TMixedValue): Int64;
Begin
 With MV do
  Case Typ of
   { bool }
   mvBool: Exit(Int64(Value.Bool));

   { char }
   mvChar: Exit(ord(Value.Char));

   { int, reference, callstack ref }
   mvInt, mvReference, mvCallstackRef: Exit(Value.Int);

   { float }
   mvFloat: Exit(Round(Value.Float)); // @TODO: inf, NaN?
  End;

 raise Exception.Create('Invalid casting: '+MixedValueTypeNames[MV.Typ]+' -> int');
End;

(* getFloat *)
Function getFloat(MV: TMixedValue): Extended;
Begin
 With MV do
  Case Typ of
   { bool }
   mvBool: Exit(uint8(Value.Bool));

   { int, reference, callstack ref }
   mvInt, mvReference, mvCallstackRef: Exit(Value.Int);

   { float }
   mvFloat: Exit(Value.Float);
  End;

 raise Exception.Create('Invalid casting: '+MixedValueTypeNames[MV.Typ]+' -> float');
End;

(* getString *)
Function getString(MV: TMixedValue): PChar;
Begin
 With MV do
  Case Typ of
   { char }
   mvChar: Exit(CopyStringToPChar(Value.Char));

   { string }
   mvString: Exit(Value.Str);
  End;

 raise Exception.Create('Invalid casting: '+MixedValueTypeNames[MV.Typ]+' -> string');
End;

(* getReference *)
Function getReference(MV: TMixedValue): Pointer;
Begin
 Result := Pointer(getInt(MV));
End;

(* getTypeName *)
Function getTypeName(MV: TMixedValue): String;
Begin
 Result := MixedValueTypeNames[MV.Typ];

 if (MV.isReg) Then
  Result += ' reg';
End;
End.
