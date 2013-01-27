{$H+}
Unit mString;

 Interface

 Implementation
Uses Machine;

{ string.length }
Procedure _length(M: TMachine);
Begin
With M do
Begin
 StackPush(Length(StackPop.getString));
End;
End;

initialization
 NewFunction('string', 'length', @_length);
End.
