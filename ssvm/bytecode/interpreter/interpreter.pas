(*
 Copyright © by Patryk Wychowaniec, 2013-2014
 All rights reserved.
*)
{$CODEALIGN PROC=16}
{$MODESWITCH ADVANCEDRECORDS}
{$H+}
Unit Interpreter;

 Interface
 Uses VMStruct, VMTypes, Opcodes, SysUtils;

 Procedure op_(const VM: PVM);

 Procedure op_NOP(const VM: PVM);
 Procedure op_STOP(const VM: PVM);
 Procedure op_PUSH(const VM: PVM);
 Procedure op_POP(const VM: PVM);
 Procedure op_ADD(const VM: PVM);
 Procedure op_SUB(const VM: PVM);
 Procedure op_MUL(const VM: PVM);
 Procedure op_DIV(const VM: PVM);
 Procedure op_NEG(const VM: PVM);
 Procedure op_MOV(const VM: PVM);
 Procedure op_JMP(const VM: PVM);
 Procedure op_TJMP(const VM: PVM);
 Procedure op_FJMP(const VM: PVM);
 Procedure op_CALL(const VM: PVM);
 Procedure op_ICALL(const VM: PVM);
 Procedure op_ACALL(const VM: PVM);
 Procedure op_RET(const VM: PVM);
 Procedure op_IF_E(const VM: PVM);
 Procedure op_IF_NE(const VM: PVM);
 Procedure op_IF_G(const VM: PVM);
 Procedure op_IF_L(const VM: PVM);
 Procedure op_IF_GE(const VM: PVM);
 Procedure op_IF_LE(const VM: PVM);
 Procedure op_STRJOIN(const VM: PVM);
 Procedure op_NOT(const VM: PVM);
 Procedure op_OR(const VM: PVM);
 Procedure op_XOR(const VM: PVM);
 Procedure op_AND(const VM: PVM);
 Procedure op_SHL(const VM: PVM);
 Procedure op_SHR(const VM: PVM);
 Procedure op_MOD(const VM: PVM);
 Procedure op_ARCRT(const VM: PVM);
 Procedure op_ARCRT1(const VM: PVM);
 Procedure op_ARSET(const VM: PVM);
 Procedure op_ARSET1(const VM: PVM);
 Procedure op_ARGET(const VM: PVM);
 Procedure op_ARGET1(const VM: PVM);
 Procedure op_ARLEN(const VM: PVM);
 Procedure op_ARRES(const VM: PVM);
 Procedure op_STRSET(const VM: PVM);
 Procedure op_STRGET(const VM: PVM);
 Procedure op_STRLEN(const VM: PVM);

 Type TOpcodeProc = Procedure(const VM: PVM);

 Const OpcodeTable: Array[TOpcodeKind] of TOpcodeProc = // opcode list
 (
  @op_NOP,
  @op_STOP,
  @op_PUSH,
  @op_POP,
  @op_ADD,
  @op_SUB,
  @op_MUL,
  @op_DIV,
  @op_NEG,
  @op_MOV,
  @op_JMP,
  @op_TJMP,
  @op_FJMP,
  @op_CALL,
  @op_ICALL,
  @op_ACALL,
  @op_RET,
  @op_IF_E,
  @op_IF_NE,
  @op_IF_G,
  @op_IF_L,
  @op_IF_GE,
  @op_IF_LE,
  @op_STRJOIN,
  @op_NOT,
  @op_OR,
  @op_XOR,
  @op_AND,
  @op_SHL,
  @op_SHR,
  @op_MOD,
  @op_ARCRT,
  @op_ARCRT1,
  @op_ARSET,
  @op_ARSET1,
  @op_ARGET,
  @op_ARGET1,
  @op_ARLEN,
  @op_ARRES,
  @op_STRSET,
  @op_STRGET,
  @op_STRLEN
 );

 Implementation
Uses VMObjects, VMStack, VMICall, VMExceptions, TypInfo;

(* InvalidArgumentsException *)
Procedure InvalidArgumentsException(const VM: PVM; const ArgList: Array of TMixedValue);
Var OpName: String;
Begin
 OpName := GetEnumName(TypeInfo(TOpcodeKind), VM^.Bytecode.getCurrentOpcode^);
 Delete(OpName, 1, 2); // remove the "o_"

 Case Length(ArgList) of
  1: VM^.ThrowException('''%s'' called with arguments: %s', [OpName, getTypeName(ArgList[0])]);
  2: VM^.ThrowException('''%s'' called with arguments: %s, %s', [OpName, getTypeName(ArgList[0]), getTypeName(ArgList[1])]);
  3: VM^.ThrowException('''%s'' called with arguments: %s, %s, %s', [OpName, getTypeName(ArgList[0]), getTypeName(ArgList[1]), getTypeName(ArgList[2])]);

  else
   VM^.ThrowException('InvalidArgumentsException()');
 End;
End;

(* CheckStringBounds *)
{
 Checks if "Index" fits in string bounds (1..Length).
}
Procedure CheckStringBounds(const VM: PVM; const Str: PVMString; const Index: VMInt);
Var Throw: Boolean = False;
    Len  : uint32;
Begin
 if (Index < 1) Then
  Throw := True;

 if (Str = nil) Then
  Len := 1 Else
  Len := Str^.Length;

 if (Index > Len) Then
  Throw := True;

 if (Throw) Then
 Begin
  if (Len = 0) Then
   VM^.ThrowException('String index out of bounds: string is empty') Else
   VM^.ThrowException('String index out of bounds: index %d is outside string range 1..%d', [Index, Len]);
 End;
End;

{ _ }
Procedure op_(const VM: PVM); // an unimplemented opcode
Begin
 VM^.ThrowException('Opcode 0x%x unimplemented!', [VM^.Bytecode.getCurrentOpcode^]);
End;

{ NOP() }
Procedure op_NOP(const VM: PVM);
Begin
End;

{ STOP() }
Procedure op_STOP(const VM: PVM);
Begin
 VM^.Stop := True;
End;

{ PUSH (value) }
Procedure op_PUSH(const VM: PVM);
Begin
 With VM^ do
 Begin
  Stack.Push(Bytecode.read_param(True));
 End;
End;

{ POP (register) }
Procedure op_POP(const VM: PVM);
Var reg, val: TMixedValue;
Label Fail;
Begin
 With VM^ do
 Begin
  val := Stack.Pop;
  reg := Bytecode.read_param;

  { POP (register) }
  if (reg.isReg) Then
  Begin
   Case reg.Typ of
    mvBool     : Regs.b[reg.RegIndex] := getBool(val);
    mvChar     : Regs.c[reg.RegIndex] := getChar(val);
    mvInt      : Regs.i[reg.RegIndex] := getInt(val);
    mvFloat    : Regs.f[reg.RegIndex] := getFloat(val);
    mvString   : Regs.s[reg.RegIndex] := getString(val);
    mvReference: Regs.r[reg.RegIndex] := getReference(val);

    else
     goto Fail;
   End;

   Exit;
  End;

  { POP (stackval) }
  if (reg.isStackval) Then
  Begin
   reg.Stackval^ := val;
   Exit;
  End;
 End;

Fail:
 InvalidArgumentsException(VM, [val, reg]);
End;

{ ADD (lvalue, value) }
Procedure op_ADD(const VM: PVM);
Var reg, param: TMixedValue;
Label Fail;
Begin
 With VM^ do
 Begin
  reg   := Bytecode.read_param;
  param := Bytecode.read_param;

  { ADD (register/memory reference, value) }
  if (reg.isReg) or (reg.isMemRef) Then
  Begin
   if (reg.isMemRef) Then
    reg.Typ := param.Typ;

   Case reg.Typ of
    mvChar : PByte(reg.MemAddr)^    += getInt(param); { char }
    mvInt  : PVMInt(reg.MemAddr)^   += getInt(param); { int }
    mvFloat: PVMFloat(reg.MemAddr)^ += getFloat(param); { float }

    else
     goto Fail;
   End;

   Exit;
  End;

  { ADD (stackval, value) }
  if (reg.isStackval) Then
  Begin
   With reg.Stackval^ do
   Begin
    Case reg.Typ of
     mvChar : Value.Char := chr(ord(Value.Char)+getInt(param)); { char }
     mvInt  : Value.Int += getInt(param); { int }
     mvFloat: Value.Float += getFloat(param); { float }

     else
      goto Fail;
    End;

    Exit;
   End;
  End;
 End;

Fail:
 InvalidArgumentsException(VM, [reg, param]);
End;

{ SUB (lvalue, value) }
Procedure op_SUB(const VM: PVM);
Var reg, param: TMixedValue;
Label Fail;
Begin
 With VM^ do
 Begin
  reg   := Bytecode.read_param;
  param := Bytecode.read_param;

  { SUB (register/memory reference, value) }
  if (reg.isReg) or (reg.isMemRef) Then
  Begin
   if (reg.isMemRef) Then
    reg.Typ := param.Typ;

   Case reg.Typ of
    mvChar : PByte(reg.MemAddr)^    -= getInt(param); { char }
    mvInt  : PVMInt(reg.MemAddr)^   -= getInt(param); { int }
    mvFloat: PVMFloat(reg.MemAddr)^ -= getFloat(param); { float }

    else
     goto Fail;
   End;

   Exit;
  End;

  { SUB (stackval, value) }
  if (reg.isStackval) Then
  Begin
   With reg.Stackval^ do
   Begin
    Case reg.Typ of
     mvChar : Value.Char := chr(ord(Value.Char)-getInt(param)); { char }
     mvInt  : Value.Int -= getInt(param); { int }
     mvFloat: Value.Float -= getFloat(param); { float }

     else
      goto Fail;
    End;

    Exit;
   End;
  End;
 End;

Fail:
 InvalidArgumentsException(VM, [reg, param]);
End;

{ MUL (lvalue, value) }
Procedure op_MUL(const VM: PVM);
Var reg, param: TMixedValue;
Label Fail;
Begin
 With VM^ do
 Begin
  reg   := Bytecode.read_param;
  param := Bytecode.read_param;

  { MUL (register/memory reference, value) }
  if (reg.isReg) or (reg.isMemRef) Then
  Begin
   if (reg.isMemRef) Then
    reg.Typ := param.Typ;

   Case reg.Typ of
    mvChar : PByte(reg.MemAddr)^    *= getInt(param); { char }
    mvInt  : PVMInt(reg.MemAddr)^   *= getInt(param); { int }
    mvFloat: PVMFloat(reg.MemAddr)^ *= getFloat(param); { float }

    else
     goto Fail;
   End;

   Exit;
  End;

  { MUL (stackval, value) }
  if (reg.isStackval) Then
  Begin
   With reg.Stackval^ do
   Begin
    Case reg.Typ of
     mvChar : Value.Char := chr(ord(Value.Char)*getInt(param)); { char }
     mvInt  : Value.Int *= getInt(param); { int }
     mvFloat: Value.Float *= getFloat(param); { float }

     else
      goto Fail;
    End;
   End;

   Exit;
  End;
 End;

Fail:
 InvalidArgumentsException(VM, [reg, param]);
End;

{ DIV (lvalue, value) }
Procedure op_DIV(const VM: PVM);
Var reg, param: TMixedValue;
Label Fail;
Begin
 With VM^ do
 Begin
  reg   := Bytecode.read_param;
  param := Bytecode.read_param;

  { DIV (register/memory reference, value) }
  if (reg.isReg) or (reg.isMemRef) Then
  Begin
   if (reg.isMemRef) Then
    reg.Typ := param.Typ;

   Case reg.Typ of
    mvChar : PByte(reg.MemAddr)^    := PByte(reg.MemAddr)^ div getInt(param); { char }
    mvInt  : PVMInt(reg.MemAddr)^   := PVMInt(reg.MemAddr)^ div getInt(param); { int }
    mvFloat: PVMFloat(reg.MemAddr)^ /= getFloat(param); { float }

    else
     goto Fail;
   End;

   Exit;
  End;

  { DIV (stackval, value) }
  if (reg.isStackval) Then
  Begin
   With reg.Stackval^ do
   Begin
    Case reg.Typ of
     mvChar : Value.Char := chr(ord(Value.Char) div getInt(param)); { char }
     mvInt  : Value.Int := Value.Int div getInt(param); { int }
     mvFloat: Value.Float /= getFloat(param); { float }

     else
      goto Fail;
    End;

    Exit;
   End;
  End;
 End;

Fail:
 InvalidArgumentsException(VM, [reg, param]);
End;

{ NEG (register/stackval) }
Procedure op_NEG(const VM: PVM);
Var reg: TMixedValue;
Label Fail;
Begin
 With VM^ do
 Begin
  reg := Bytecode.read_param;

  { NEG (register) }
  if (reg.isReg) Then
  Begin
   Case reg.Typ of
    mvInt  : PVMInt(reg.MemAddr)^ := -PVMInt(reg.MemAddr)^; { int }
    mvFloat: PVMFloat(reg.MemAddr)^ := -PVMFloat(reg.MemAddr)^; { float }

    else
     goto Fail;
   End;

   Exit;
  End;

  { NEG (stackval) }
  if (reg.isStackval) Then
  Begin
   With reg.Stackval^ do
   Begin
    Case reg.Typ of
     mvInt  : Value.Int   := -Value.Int; { int }
     mvFloat: Value.Float := -Value.Float; { float }

     else
      goto Fail;
    End;

    Exit;
   End;
  End;
 End;

Fail:
 InvalidArgumentsException(VM, [reg]);
End;

{ MOV (lvalue, value) }
Procedure op_MOV(const VM: PVM);
Var reg, val: TMixedValue;
Label Fail;
Begin
 With VM^ do
 Begin
  reg := Bytecode.read_param;
  val := Bytecode.read_param(True);

  { MOV (register/memory reference, value) }
  if (reg.isReg) or (reg.isMemRef) Then
  Begin
   if (reg.isMemRef) Then
    reg.Typ := val.Typ;

   Case reg.Typ of
    mvBool     : PVMBool(reg.MemAddr)^  := getBool(val); { bool }
    mvChar     : PVMChar(reg.MemAddr)^  := getChar(val); { char }
    mvInt      : PVMInt(reg.MemAddr)^   := getInt(val); { int }
    mvFloat    : PVMFloat(reg.MemAddr)^ := getFloat(val); { float }
    mvString   : PPointer(reg.MemAddr)^ := getString(val); { string }
    mvReference: PPointer(reg.MemAddr)^ := getReference(val); { reference }

    else
     goto Fail;
   End;

   Exit;
  End;

  { MOV (stackval, value) }
  if (reg.isStackval) Then
  Begin
   reg.Stackval^ := val;
   Exit;
  End;
 End;

Fail:
 InvalidArgumentsException(VM, [reg, val]);
End;

{ JMP (const int) }
Procedure op_JMP(const VM: PVM);
Var NewAddr: VMIReference;
Begin
 With VM^ do
 Begin
  NewAddr := VMIReference(Bytecode.getPosition) + BEtoN(Pint64(Bytecode.getCurrentOpcode+1)^)-1;
  {
   @Note: '-1' because instruction pointer will be incremented after this JMP finishes executing and finally we'd jump one byte further
  }

  Bytecode.setPosition(Pointer(NewAddr));
 End;
End;

{ TJMP (const int) }
Procedure op_TJMP(const VM: PVM);
Var NewAddr: VMIReference;
Begin
 With VM^ do
 Begin
  if (Regs.b[5]) Then
  Begin
   // read parameter and jump
   NewAddr := VMIReference(Bytecode.getPosition) + BEtoN(Pint64(Bytecode.getCurrentOpcode+1)^)-1;
   Bytecode.setPosition(Pointer(NewAddr));
  End Else
  Begin
   // skip opcode
   Bytecode.setPosition(Bytecode.getPosition+8);
  End;
 End;
End;

{ FJMP (const int) }
Procedure op_FJMP(const VM: PVM);
Var NewAddr: VMIReference;
Begin
 With VM^ do
 Begin
  if (Regs.b[5]) Then
  Begin
   // skip opcode
   Bytecode.setPosition(Bytecode.getPosition+8);
  End Else
  Begin
   // read parameter and jump
   NewAddr := VMIReference(Bytecode.getPosition) + BEtoN(Pint64(Bytecode.getCurrentOpcode+1)^)-1;
   Bytecode.setPosition(Pointer(NewAddr));
  End;
 End;
End;

{ CALL (const int) }
Procedure op_CALL(const VM: PVM);
Var NewAddr: VMIReference;
    Elem   : TStackElement;
Begin
 With VM^ do
 Begin
  NewAddr := VMIReference(Bytecode.getPosition) + BEtoN(Pint64(Bytecode.getCurrentOpcode+1)^)-1;

  // push the old position onto the stack
  Elem.Reset;
  Elem.Typ       := mvCallstackRef;
  Elem.Value.Int := VMInt(Bytecode.getPosition+8);
  Stack.Push(Elem);

  // jump
  Bytecode.setPosition(Pointer(NewAddr));
 End;
End;

{ ICALL (const string) }
Procedure op_ICALL(const VM: PVM);
Var Name  : String;
    NameVS: PVMString;
    Call  : PInternalCall;
    Params: PMixedValue;
    Result: PMixedValue;
    I     : int16;

    Param: TMixedValue;
Begin
 With VM^ do
 Begin
  NameVS := getString(Bytecode.read_param);

  Name := NameVS^.asString;

  // VM^.VMStringList.Remove(NameVS);

  if (Name[1] = 'v') and (Name[2] = 'm') and (Name[3] = '.') Then
  Begin
   {$I interpreter_icalls.pas}
   Exit;
  End;

  { user call }
  For Call in InternalCallList Do // each icall
  Begin
   if (AnsiCompareStr(Call^.FullName, Name) = 0) Then // is this what we are searching for?
   Begin
    Params := AllocMem(Call^.ParamCount*sizeof(TMixedValue));

    For I := 0 To Call^.ParamCount-1 Do // get parameters
     Params[I] := Stack.Pop;

    New(Result);
    Result^.Reset;

    Call^.Handler(VM, @Params[0], Result); // call handler

    if (Result^.Typ <> mvNone) Then // push result
     Stack.Push(Result^);

    Dispose(Result);
    Dispose(Params);

    Exit;
   End;
  End;

  VM^.ThrowException('Undefined internal call: %s', [Name]);
 End;
End;

{ ACALL (int) }
Procedure op_ACALL(const VM: PVM);
Var NewAddr: VMIReference;
    Elem   : TStackElement;
Begin
 With VM^ do
 Begin
  NewAddr := getInt(Bytecode.read_param);

  Elem.Typ       := mvCallstackRef;
  Elem.Value.Int := VMIReference(Bytecode.getPosition);
  Stack.Push(Elem); // push the old position onto the stack

  Bytecode.setPosition(PByte(NewAddr));
 End;
End;

{ RET() }
Procedure op_RET(const VM: PVM);
Begin
 With VM^ do
  Bytecode.setPosition(Pointer(getInt(Stack.Pop)));
End;

{ IF_E (value, value) }
Procedure op_IF_E(const VM: PVM);
Var P1, P2: TMixedValue;
Begin
 With VM^ do
 Begin
  P1 := Bytecode.read_param;
  P2 := Bytecode.read_param;

  Regs.b[5] := (P1 = P2); // set 'IF' register
 End;
End;

{ IF_NE (value, value) }
Procedure op_IF_NE(const VM: PVM);
Var P1, P2: TMixedValue;
Begin
 With VM^ do
 Begin
  P1 := Bytecode.read_param;
  P2 := Bytecode.read_param;

  Regs.b[5] := (P1 <> P2); // set 'IF' register
 End;
End;

{ IF_G (value, value) }
Procedure op_IF_G(const VM: PVM);
Var P1, P2: TMixedValue;
Begin
 With VM^ do
 Begin
  P1 := Bytecode.read_param;
  P2 := Bytecode.read_param;

  Regs.b[5] := (P1 > P2); // set 'IF' register
 End;
End;

{ IF_L (value, value) }
Procedure op_IF_L(const VM: PVM);
Var P1, P2: TMixedValue;
Begin
 With VM^ do
 Begin
  P1 := Bytecode.read_param;
  P2 := Bytecode.read_param;

  Regs.b[5] := (P1 < P2); // set 'IF' register
 End;
End;

{ IF_GE (value, value) }
Procedure op_IF_GE(const VM: PVM);
Var P1, P2: TMixedValue;
Begin
 With VM^ do
 Begin
  P1 := Bytecode.read_param;
  P2 := Bytecode.read_param;

  Regs.b[5] := (P1 >= P2); // set 'IF' register
 End;
End;

{ IF_LE (value, value) }
Procedure op_IF_LE(const VM: PVM);
Var P1, P2: TMixedValue;
Begin
 With VM^ do
 Begin
  P1 := Bytecode.read_param;
  P2 := Bytecode.read_param;

  Regs.b[5] := (P1 <= P2); // set 'IF' register
 End;
End;

{ STRJOIN (lvalue, char/string) }
Procedure op_STRJOIN(const VM: PVM);
Var reg, param: TMixedValue;
Label Fail;
Begin
 With VM^ do
 Begin
  reg   := Bytecode.read_param;
  param := Bytecode.read_param;

  { STRJOIN (register/memory reference, char/string) }
  if (reg.isReg) or (reg.isMemRef) Then
  Begin
   if (reg.isMemRef) Then
    reg.Typ := param.Typ;

   Case reg.Typ of
    mvString: StringConcat(PPVMString(reg.MemAddr)^, getString(param)); // string

    else
     goto Fail;
   End;

   Exit;
  End;

  { STRJOIN (stackval, char/string) }
  if (reg.isStackval) Then
  Begin
   With reg.Stackval^ do
   Begin
    Case reg.Typ of
     mvString: StringConcat(Value.Str, getString(param)); // string

     else
      goto Fail;
    End;

    Exit;
   End;
  End;
 End;

Fail:
 InvalidArgumentsException(VM, [reg, param]);
End;

{ NOT (register/stackval) }
Procedure op_NOT(const VM: PVM);
Var reg: TMixedValue;
Label Fail;
Begin
 With VM^ do
 Begin
  reg := Bytecode.read_param;

  { NOT (register) }
  if (reg.isReg) Then
  Begin
   Case reg.Typ of
    mvBool: PVMBool(reg.MemAddr)^ := not PVMBool(reg.MemAddr)^; { bool }
    mvInt : PVMInt(reg.MemAddr)^ := not PVMInt(reg.MemAddr)^; { int }

    else
     goto Fail;
   End;

   Exit;
  End;

  { NOT (stackval) }
  if (reg.isStackval) Then
  Begin
   With reg.Stackval^ do
   Begin
    Case reg.Typ of
     mvBool: Value.Bool := not Value.Bool; { bool }
     mvInt : Value.Int  := not Value.Int; { int }

     else
      goto Fail;
    End;

    Exit;
   End;
  End;
 End;

Fail:
 InvalidArgumentsException(VM, [reg]);
End;

{ OR (lvalue, value) }
Procedure op_OR(const VM: PVM);
Var reg, param: TMixedValue;
Label Fail;
Begin
 With VM^ do
 Begin
  reg   := Bytecode.read_param;
  param := Bytecode.read_param;

  { OR (register/memory reference, value) }
  if (reg.isReg) or (reg.isMemRef) Then
  Begin
   if (reg.isMemRef) Then
    reg.Typ := param.Typ;

   Case reg.Typ of
    mvBool: PVMBool(reg.MemAddr)^ := PVMBool(reg.MemAddr)^ or getBool(param); { bool }
    mvInt : PVMInt(reg.MemAddr)^  := PVMInt(reg.MemAddr)^ or getInt(Param); { int }

    else
     goto Fail;
   End;

   Exit;
  End;

  { OR (stackval, value) }
  if (reg.isStackval) Then
  Begin
   With reg.Stackval^ do
   Begin
    Case reg.Typ of
     mvBool: Value.Bool := Value.Bool or getBool(param); { bool }
     mvInt : Value.Int  := Value.Int or getInt(param); { int }

     else
      goto Fail;
    End;

    Exit;
   End;
  End;
 End;

Fail:
 InvalidArgumentsException(VM, [reg, param]);
End;

{ XOR (lvalue, value) }
Procedure op_XOR(const VM: PVM);
Var reg, param: TMixedValue;
Label Fail;
Begin
 With VM^ do
 Begin
  reg   := Bytecode.read_param;
  param := Bytecode.read_param;

  { XOR (register/memory reference, value) }
  if (reg.isReg) Then
  Begin
   if (reg.isMemRef) Then
    reg.Typ := param.Typ;

   Case reg.Typ of
    mvBool: PVMBool(reg.MemAddr)^ := PVMBool(reg.MemAddr)^ xor getBool(param); { bool }
    mvInt : PVMInt(reg.MemAddr)^  := PVMInt(reg.MemAddr)^ xor getInt(Param); { int }

    else
     goto Fail;
   End;

   Exit;
  End;

  { XOR (stackval, value) }
  if (reg.isStackval) Then
  Begin
   With reg.Stackval^ do
   Begin
    Case reg.Typ of
     mvBool: Value.Bool := Value.Bool xor getBool(param); { bool }
     mvInt : Value.Int  := Value.Int xor getInt(param); { int }

     else
      goto Fail;
    End;

    Exit;
   End;
  End;
 End;

Fail:
 InvalidArgumentsException(VM, [reg, param]);
End;

{ AND (lvalue, value) }
Procedure op_AND(const VM: PVM);
Var reg, param: TMixedValue;
Label Fail;
Begin
 With VM^ do
 Begin
  reg   := Bytecode.read_param;
  param := Bytecode.read_param;

  { AND (register/memory reference, value) }
  if (reg.isReg) or (reg.isMemRef) Then
  Begin
   if (reg.isMemRef) Then
    reg.Typ := param.Typ;

   Case reg.Typ of
    mvBool: PVMBool(reg.MemAddr)^ := PVMBool(reg.MemAddr)^ and getBool(param); { bool }
    mvInt : PVMInt(reg.MemAddr)^  := PVMInt(reg.MemAddr)^ and getInt(Param); { int }

    else
     goto Fail;
   End;

   Exit;
  End;

  { AND (stackval, value) }
  if (reg.isStackval) Then
  Begin
   With reg.Stackval^ do
   Begin
    Case reg.Typ of
     mvBool: Value.Bool := Value.Bool and getBool(param); { bool }
     mvInt : Value.Int  := Value.Int and getInt(param); { int }

     else
      goto Fail;
    End;

    Exit;
   End;
  End;
 End;

Fail:
 InvalidArgumentsException(VM, [reg, param]);
End;

{ SHL (lvalue, value) }
Procedure op_SHL(const VM: PVM);
Var reg, param: TMixedValue;
Label Fail;
Begin
 With VM^ do
 Begin
  reg   := Bytecode.read_param;
  param := Bytecode.read_param;

  { SHL (register/memory reference, value) }
  if (reg.isReg) or (reg.isMemRef) Then
  Begin
   if (reg.isMemRef) Then
    reg.Typ := param.Typ;

   Case reg.Typ of
    mvInt: PVMInt(reg.MemAddr)^ := PVMInt(reg.MemAddr)^ shl getInt(Param); { int }

    else
     goto Fail;
   End;

   Exit;
  End;

  { SHL (stackval, value) }
  if (reg.isStackval) Then
  Begin
   With reg.Stackval^ do
   Begin
    Case reg.Typ of
     mvInt: Value.Int := Value.Int shl getInt(param); { int }

     else
      goto Fail;
    End;

    Exit;
   End;
  End;
 End;

Fail:
 InvalidArgumentsException(VM, [reg, param]);
End;

{ SHR (lvalue, value) }
Procedure op_SHR(const VM: PVM);
Var reg, param: TMixedValue;
Label Fail;
Begin
 With VM^ do
 Begin
  reg   := Bytecode.read_param;
  param := Bytecode.read_param;

  { SHR (register/memory reference, value) }
  if (reg.isReg) or (reg.isMemRef) Then
  Begin
   if (reg.isMemRef) Then
    reg.Typ := param.Typ;

   Case reg.Typ of
    mvInt: PVMInt(reg.MemAddr)^ := PVMInt(reg.MemAddr)^ shr getInt(Param); { int }

    else
     goto Fail;
   End;

   Exit;
  End;

  { SHR (stackval, value) }
  if (reg.isStackval) Then
  Begin
   With reg.Stackval^ do
   Begin
    Case reg.Typ of
     mvInt: Value.Int := Value.Int shr getInt(param); { int }

     else
      goto Fail;
    End;

    Exit;
   End;
  End;
 End;

Fail:
 InvalidArgumentsException(VM, [reg, param]);
End;

{ MOD (lvalue, value) }
Procedure op_MOD(const VM: PVM);
Var reg, param: TMixedValue;
Label Fail;
Begin
 With VM^ do
 Begin
  reg   := Bytecode.read_param;
  param := Bytecode.read_param;

  { MOD (register/memory reference, value) }
  if (reg.isReg) or (reg.isMemRef) Then
  Begin
   if (reg.isMemRef) Then
    reg.Typ := param.Typ;

   Case reg.Typ of
    mvChar: PVMChar(reg.MemAddr)^ := VMChar(VMIChar(PVMChar(reg.MemAddr)^) mod VMIChar(getChar(Param))); { char }
    mvInt : PVMInt(reg.MemAddr)^ := PVMInt(reg.MemAddr)^ mod getInt(Param); { int }

    else
     goto Fail;
   End;

   Exit;
  End Else

  { MOD (stackval, value) }
  if (reg.isReg) Then
  Begin
   With reg.Stackval^ do
   Begin
    Case reg.Typ of
     mvChar: Value.Char := VMChar(VMIChar(Value.Char) mod VMIChar(getInt(param))); { char }
     mvInt : Value.Int := Value.Int mod getInt(param); { int }

     else
      goto Fail;
    End;

    Exit;
   End;
  End;
 End;

Fail:
 InvalidArgumentsException(VM, [reg, param]);
End;

{ ARCRT (reg/stvl/mem arrayReference, int arrayType, const int dimensionCount) }
Procedure op_ARCRT(const VM: PVM);
Var arrayReference, arrayType, dimensionCount: TMixedValue;
    SizeArray                                : TIndexArray;

    ArrayObj: TSSVMArray;
    I       : uint32;
Label Fail;
Begin
 With VM^ do
 Begin
  // read parameters
  arrayReference := Bytecode.read_param;
  arrayType      := Bytecode.read_param;
  dimensionCount := Bytecode.read_param;

  // read dimension sizes
  SetLength(SizeArray, getInt(dimensionCount));
  For I := 0 To High(SizeArray) Do
   SizeArray[I] := getInt(Stack.Pop);

  // create array
  ArrayObj := TSSVMArray.Create(VM, getInt(arrayType), SizeArray);

  // save result if register
  if (arrayReference.isReg) Then
  Begin
   if (arrayReference.Typ = mvReference) Then
    Regs.r[arrayReference.RegIndex] := ArrayObj Else
    goto Fail;
  End Else

  // save result if stackval
  if (arrayReference.isStackval) Then
  Begin
   With arrayReference do
   Begin
    Stackval^.Typ       := mvReference;
    Stackval^.Value.Int := VMIReference(ArrayObj);
   End;
  End Else

  // save result if memref
  if (arrayReference.isMemRef) Then
  Begin
   PPointer(arrayReference.MemAddr)^ := ArrayObj;
  End Else

  // fail otherwise
  Begin
   goto Fail;
  End;

  Exit;
 End;

Fail:
 InvalidArgumentsException(VM, [arrayReference, arrayType, dimensionCount]);
End;

{ ARCRT1 (reg/stvl/mem arrayReference, int arrayType, int dimensionSize) }
Procedure op_ARCRT1(const VM: PVM);
Var arrayReference, arrayType, dimensionSize: TMixedValue;

    ArrayObj: TSSVMArray;
    I       : uint32;
Label Fail;
Begin
 With VM^ do
 Begin
  // read parameters
  arrayReference := Bytecode.read_param;
  arrayType      := Bytecode.read_param;
  dimensionSize  := Bytecode.read_param;

  // create array
  ArrayObj := TSSVMArray.Create(VM, getInt(arrayType), getInt(dimensionSize));

  // save result if register
  if (arrayReference.isReg) Then
  Begin
   if (arrayReference.Typ = mvReference) Then
    Regs.r[arrayReference.RegIndex] := ArrayObj Else
    goto Fail;
  End Else

  // save result if stackval
  if (arrayReference.isStackval) Then
  Begin
   With arrayReference do
   Begin
    Stackval^.Typ       := mvReference;
    Stackval^.Value.Int := VMIReference(ArrayObj);
   End;
  End Else

  // save result if memref
  if (arrayReference.isMemRef) Then
  Begin
   PPointer(arrayReference.MemAddr)^ := ArrayObj;
  End Else

  // fail otherwise
  Begin
   goto Fail;
  End;

  Exit;
 End;

Fail:
 InvalidArgumentsException(VM, [arrayReference, arrayType, dimensionSize]);
End;

{ ARSET (reg/stvl/mem arrayReference, int indexCount, newValue) }
Procedure op_ARSET(const VM: PVM);
Var arrayReference, indexCount, newValue: TMixedValue;
    IndexArray                          : TIndexArray;

    ArrayPnt: TSSVMArray;

    I: uint32;
Label Fail;
Begin
 With VM^ do
 Begin
  // read parameters
  arrayReference := Bytecode.read_param;
  indexCount     := Bytecode.read_param;
  newValue       := Bytecode.read_param;

  // read indexes
  SetLength(IndexArray, getInt(indexCount));
  For I := 0 To High(IndexArray) Do
   IndexArray[I] := getInt(Stack.Pop);

  // fetch pointer
  ArrayPnt := TSSVMArray(CheckObject(getReference(arrayReference)));

  // set value
  ArrayPnt.setValue(IndexArray, newValue);
 End;
End;

{ ARSET1 (reg/stvl/mem arrayReference, int indexId, newValue) }
Procedure op_ARSET1(const VM: PVM);
Var arrayReference, indexId, newValue: TMixedValue;

    ArrayPnt: TSSVMArray;
Begin
 With VM^ do
 Begin
  // read parameters
  arrayReference := Bytecode.read_param;
  indexId        := Bytecode.read_param;
  newValue       := Bytecode.read_param;

  // fetch pointer
  ArrayPnt := TSSVMArray(CheckObject(getReference(arrayReference)));

  // set value
  ArrayPnt.setValue(getInt(indexId), newValue);
 End;
End;

{ ARGET (reg/stvl/mem arrayReference, int indexCount, out outValue) }
Procedure op_ARGET(const VM: PVM);
Var arrayReference, indexCount, outValue: TMixedValue;
    IndexArray                          : TIndexArray;

    ArrayPnt: TSSVMArray;
    AValue  : TMixedValue;

    I: uint32;
Label Fail;
Begin
 With VM^ do
 Begin
  // reset temporary variable
  AValue.Reset;

  // read parameters
  arrayReference := Bytecode.read_param;
  indexCount     := Bytecode.read_param;
  outValue       := Bytecode.read_param;

  // read indexes
  SetLength(IndexArray, getInt(indexCount));
  For I := 0 To High(IndexArray) Do
   IndexArray[I] := getInt(Stack.Pop);

  // fetch pointer
  ArrayPnt := TSSVMArray(CheckObject(getReference(arrayReference)));

  // get value
  AValue := ArrayPnt.getValue(IndexArray);

  // save result (register)
  if (outValue.isReg) Then
  Begin
   Case outValue.Typ of
    mvBool     : Regs.b[outValue.RegIndex] := getBool(AValue);
    mvChar     : Regs.c[outValue.RegIndex] := getChar(AValue);
    mvInt      : Regs.i[outValue.RegIndex] := getInt(AValue);
    mvFloat    : Regs.f[outValue.RegIndex] := getFloat(AValue);
    mvString   : Regs.s[outValue.RegIndex] := getString(AValue);
    mvReference: Regs.r[outValue.RegIndex] := getReference(AValue);

    else
     goto Fail;
   End;
  End Else

  // save result (stackval)
  if (outValue.isStackval) Then
  Begin
   outValue.Stackval^ := AValue;
  End Else

  // throw exception if invalid result parameter
  Begin
   goto Fail;
  End;

  Exit;
 End;

Fail:
 InvalidArgumentsException(VM, [arrayReference, indexCount, outValue]);
End;

{ ARGET1 (reg/stvl/mem arrayReference, int indexId, out outValue) }
Procedure op_ARGET1(const VM: PVM);
Var arrayReference, indexId, outValue: TMixedValue;
    ArrayPnt                         : TSSVMArray;
    AValue                           : TMixedValue;
Label Fail;
Begin
 With VM^ do
 Begin
  // reset temporary variable
  AValue.Reset;

  // read parameters
  arrayReference := Bytecode.read_param;
  indexId        := Bytecode.read_param;
  outValue       := Bytecode.read_param;

  // fetch pointer
  ArrayPnt := TSSVMArray(CheckObject(getReference(arrayReference)));

  // get value
  AValue := ArrayPnt.getValue(getInt(indexId));

  // save result (register)
  if (outValue.isReg) Then
  Begin
   Case outValue.Typ of
    mvBool     : Regs.b[outValue.RegIndex] := getBool(AValue);
    mvChar     : Regs.c[outValue.RegIndex] := getChar(AValue);
    mvInt      : Regs.i[outValue.RegIndex] := getInt(AValue);
    mvFloat    : Regs.f[outValue.RegIndex] := getFloat(AValue);
    mvString   : Regs.s[outValue.RegIndex] := getString(AValue);
    mvReference: Regs.r[outValue.RegIndex] := getReference(AValue);

    else
     goto Fail;
   End;
  End Else

  // save result (stackval)
  if (outValue.isStackval) Then
  Begin
   outValue.Stackval^ := AValue;
  End Else

  // throw exception if invalid result parameter
  Begin
   goto Fail;
  End;

  Exit;
 End;

Fail:
 InvalidArgumentsException(VM, [arrayReference, indexId, outValue]);
End;

{ ARLEN (reg/stvl/mem arrayReference, reg/stvl/mem int arrayLength) }
Procedure op_ARLEN(const VM: PVM);
Var arrayReference, arrayLength: TMixedValue;
    DimSize                    : uint32;

    ArrayPnt: Pointer;
Label Fail;
Begin
 With VM^ do
 Begin
  // read parameters
  arrayReference := Bytecode.read_param;
  arrayLength    := Bytecode.read_param;

  // fetch pointer
  ArrayPnt := TSSVMArray(CheckObject(getReference(arrayReference)));

  // fetch array size
  DimSize := TSSVMArray(CheckObject(ArrayPnt)).getSize;

  // save array size to register
  if (arrayLength.isReg) Then
  Begin
   Regs.i[arrayLength.RegIndex] := DimSize;
  End Else

  // save array size to stackval
  if (arrayLength.isStackval) Then
  Begin
   With arrayLength do
   Begin
    Stackval^.Typ       := mvInt;
    Stackval^.Value.Int := DimSize;
   End;
  End Else

  // save array size to memref
  if (arrayLength.isMemRef) Then
  Begin
   PVMInt(arrayLength.MemAddr)^ := DimSize;
  End Else

  // or fail, if none of the above fits the parameter list
  Begin
   goto Fail;
  End;

  Exit;
 End;

Fail:
 InvalidArgumentsException(VM, [arrayReference, arrayLength]);
End;

{ ARRES (reg/stvl/mem arrayReference, reg/stvl/mem int newLength) }
Procedure op_ARRES(const VM: PVM);
Var arrayReference, newLength: TMixedValue;
    ArrayPnt                 : TSSVMArray;
Begin
 With VM^ do
 Begin
  // read parameters
  arrayReference := Bytecode.read_param;
  newLength      := Bytecode.read_param;

  // fetch pointer
  ArrayPnt := TSSVMArray(CheckObject(getReference(arrayReference)));

  // resize
  ArrayPnt.Resize(getInt(newLength));
 End;
End;

{ STRSET (reg/stvl/mem string modString, int charIndex, char newValue) }
Procedure op_STRSET(const VM: PVM);
Var modString, charIndex, newValue: TMixedValue;

    Index: VMInt;
    Str  : PVMString;
Label Fail;
Begin
 With VM^ do
 Begin
  // read parameter list
  modString := Bytecode.read_param;
  charIndex := Bytecode.read_param;
  newValue  := Bytecode.read_param;

  // get index
  Index := getInt(charIndex);

  // fetch string if modString is register
  if (modString.isReg) Then
  Begin
   Str := getString(modString);
  End Else

  // fetch string if modString is stackval
  if (modString.isStackval) Then
  Begin
   Str := getString(modString.Stackval^);
  End Else

  // fetch string if modString is memory reference
  if (modString.isMemRef) Then
  Begin
   Str := PPointer(modString.MemAddr)^;
  End Else

  // give up otherwise
  Begin
   goto Fail;
  End;

  // check bounds
  CheckStringBounds(VM, Str, Index);

  // modify string
  Str^.Data[Index-1] := getChar(newValue);

  Exit;
 End;

Fail:
 InvalidArgumentsException(VM, [modString, charIndex, newValue]);
End;

{ STRGET (string modString, int charIndex, reg/stvl/mem char outValue) }
Procedure op_STRGET(const VM: PVM);
Var modString, charIndex, outValue: TMixedValue;

    Index: VMInt;
    Char : System.Char;
    Str  : PVMString;
Label Fail;
Begin
 With VM^ do
 Begin
  // read parameters
  modString := Bytecode.read_param;
  charIndex := Bytecode.read_param;
  outValue  := Bytecode.read_param;

  // get index
  Index := getInt(charIndex);

  // fetch string
  Str := getString(modString);

  // check bounds
  CheckStringBounds(VM, Str, Index);

  // fetch char
  Char := Str^.Data[Index-1];

  // save char to register
  if (outValue.isReg) and (outValue.Typ = mvChar) Then
  Begin
   Regs.c[outValue.RegIndex] := Char;
  End Else

  // save char to stackval
  if (outValue.isStackval) Then
  Begin
   With outValue do
   Begin
    Stackval^.Typ        := mvChar;
    Stackval^.Value.Char := Char;
   End;
  End Else

  // save char to memref
  if (outValue.isMemRef) Then
  Begin
   PChar(outValue.MemAddr)^ := Char;
  End Else

  // throw an exception otherwise
  Begin
   goto Fail;
  End;

  Exit;
 End;

Fail:
 InvalidArgumentsException(VM, [modString, charIndex, outValue]);
End;

{ STRLEN (string register, out int register/stackval) }
Procedure op_STRLEN(const VM: PVM);
Var strreg, outreg: TMixedValue;
    TmpStr        : PVMString;
Begin
 With VM^ do
 Begin
  strreg := Bytecode.read_param;
  outreg := Bytecode.read_param;

  TmpStr := getString(strreg);

  { STRLEN (string, register) }
  if (outreg.isReg) Then
  Begin
   Regs.i[outreg.RegIndex] := TmpStr^.Length;
   Exit;
  End;

  { STRLEN (string, stackval) }
  if (outreg.isStackval) Then
  Begin
   outreg.Stackval^.Typ       := mvInt;
   outreg.Stackval^.Value.Int := TmpStr^.Length;
   Exit;
  End;
 End;

 InvalidArgumentsException(VM, [strreg, outreg]);
End;
End.
