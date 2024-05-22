{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024
  @website(https://www.gladir.com/bugtracker)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program BUGTRK;

Uses Crt,DOS;

Const
 BugHeaderFile='DATA\BUG.HDR';
 BugDataFile='DATA\BUG.DTA';
 ProjectHeaderFile='DATA\PROJECT.HDR';
 ProjectDataFile='DATA\PROJECT.DTA';
 UserHeaderFile='DATA\USER.HDR';
 UserDataFile='DATA\USER.DTA';

  { Status }
 stFeedback=20;
 stAcknowledged=30;
 stConfirmed=40;
 stAssigned=50;
 stResolved=80;
 stClosed=90;

  { R‚solution }
 rsOpen=10;
 rsFixed=20;
 rsReopened=30;
 rsUnableToReproduce=40;
 rsNotFixable=50;
 rsDuplicate=60;
 rsNotABug=70;
 rsSuspended=80;
 rsWontFix=90;

  { Priorit‚ }
 prNone=10;
 prLow=20;
 prNormal=30;
 prHigh=40;
 prUrgent=50;
 prImmediate=60;

  { S‚verit‚ }
 svFeature=10;
 svTrivial=20;
 svText=30;
 svTweak=40;
 svMinor=50;
 svMajor=60;
 svCrash=70;
 svBlock=80;

  { Reproductible }
 rpAlways=10;
 rpSomestimes=30;
 rpRandom=50;
 rpHaveNotTried=70;
 rpUnableToDuplicate=90;
 rpNotApplicable=100;

  { Touche clavier }
 kbNoKey=0;{Pas de touche}
 kbDn=$5000;{Fleche Bas}
 kbEnter=$1C0D;{Enter}
 kbEsc=$011B;{Escape}
 kbShiftTab=$0F00;{Shift+Tabulation}
 kbTab=$0F09;{Tabulation}
 kbUp=$4800;{Fleche Haut}

Type
 HeaderFileRec=Record
  DataFileName:String;
  AutoIncrementID:LongInt;
 End;

 UserRec=Record
  UserID:LongInt;
  FirstName:String;
  LastName:String;
 End;

 ProjectRec=Record
  ProjectID:LongInt;
  ProjectCode:String;
  Name:String;
  Version:String;
  SourceVersionLink:String;
  DocumentationLink:String;
 End;

 BugRec=Record
  BugID:LongInt;
  Summary:String;
  Description:String;
  DateSubmit,DateDue,LastUpdate:DateTime;
  Reporter_UserID:LongInt;
  AssignedTo_UserID:LongInt;
  ProjectID:LongInt;
  Status:Byte;           { Constante st??? }
  Priority:Byte;         { Constante pr??? }
  Severity:Byte;         { Constante sv??? }
  Resolution:Byte;       { Constante rs??? }
  Reproductibility:Byte; { Constante rp??? }
  ProductVersion:String[20];
  TargetVersion:String[20];
 End;

Var
 CurrDialog:Byte;
 ShowASCII128:Boolean;
 I:Integer;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function PadRight(S:String;Space:Byte):String;
Var
 I:Byte;
Begin
 If Length(S)<Space Then For I:=Length(S)+1 to Space do S:=S+' ';
 PadRight:=S;
End;

Function IncrementID(FileName:String):LongInt;
Var
 HeaderFile:File of HeaderFileRec;
 Data:HeaderFileRec;
Begin
 IncrementID:=1;
 {$I-}Assign(HeaderFile,FileName);
 Reset(HeaderFile);{$I+}
 If IOResult=0 Then Begin
  Read(HeaderFile,Data);
  Close(HeaderFile);
  Inc(Data.AutoIncrementID);
  IncrementID:=Data.AutoIncrementID;
  {$I-}Assign(HeaderFile,FileName);
  Rewrite(HeaderFile);{$I+}
  If IOResult=0 Then Begin
   Write(HeaderFile,Data);
   Close(HeaderFile);
  End;
 End
  Else
 Begin
  {$I-}Rewrite(HeaderFile);{$I+}
  If IOResult=0 Then Begin
   FillChar(Data,SizeOf(Data),0);
   Data.AutoIncrementID:=1;
   Data.DataFileName:=FileName;
   Write(HeaderFile,Data);
   Close(HeaderFile);
  End;
 End;
End;

Function AddBug(Var Bug:BugRec):LongInt;
Var
 BugFile:File of BugRec;
Begin
 AddBug:=0;
 Bug.BugID:=IncrementID(BugHeaderFile);
 {$I-}Assign(BugFile,BugDataFile);
 Reset(BugFile);
 If IOResult<>0 Then Rewrite(BugFile);{$I+}
 If IOResult=0 Then Begin
  Seek(BugFile,FileSize(BugFile));
  Write(BugFile,Bug);
  Close(BugFile);
  AddBug:=Bug.BugID;
 End;
End;

Function UpdateBug(Var Bug:BugRec):Boolean;
Var
 Pos:LongInt;
 BugFile:File of BugRec;
 CurrRec:BugRec;
Begin
 UpdateBug:=False;
 {$I-}Assign(BugFile,BugDataFile);
 Reset(BugFile);{$I+}
 If IOResult=0 Then Begin
  Pos:=0;
  Seek(BugFile,0);
  While Not EOF(BugFile)do Begin
   Read(BugFile,CurrRec);
   If(CurrRec.BugID=Bug.BugID)Then BEgin
    Seek(BugFile,Pos);
    Write(BugFile,Bug);
    UpdateBug:=True;
    Break;
   End;
   Inc(Pos);
  End;
  Close(BugFile);
 End;
End;

Function DeleteBug(BugID:LongInt):Boolean;
Var
 Pos:LongInt;
 BugFile:File of BugRec;
 CurrRec:BugRec;
Begin
 DeleteBug:=False;
 {$I-}Assign(BugFile,BugDataFile);
 Reset(BugFile);{$I+}
 If IOResult=0 Then Begin
  Pos:=0;
  Seek(BugFile,0);
  While Not EOF(BugFile)do Begin
   Read(BugFile,CurrRec);
   If(CurrRec.BugID=BugID)Then BEgin
    Seek(BugFile,Pos);
    CurrRec.BugID:=0;
    Write(BugFile,CurrRec);
    DeleteBug:=True;
    Break;
   End;
   Inc(Pos);
  End;
  Close(BugFile);
 End;
End;

Function ReadBug(BugID:LongInt;Var Bug:BugRec):Boolean;
Var
 BugFile:File of BugRec;
 CurrRec:BugRec;
Begin
 ReadBug:=False;
 {$I-}Assign(BugFile,BugDataFile);
 Reset(BugFile);{$I+}
 If IOResult=0 Then Begin
  Seek(BugFile,0);
  While Not EOF(BugFile)do Begin
   Read(BugFile,CurrRec);
   If(CurrRec.BugID=BugID)Then BEgin
    Bug:=CurrRec;
    ReadBug:=True;
    Break;
   End;
  End;
  Close(BugFile);
 End;
End;

Function AddUser(Var User:UserRec):LongInt;
Var
 UserFile:File of UserRec;
Begin
 AddUser:=0;
 User.UserID:=IncrementID(UserHeaderFile);
 {$I-}Assign(UserFile,UserDataFile);
 Reset(UserFile);
 If IOResult<>0 Then Rewrite(UserFile);{$I+}
 If IOResult=0 Then Begin
  Seek(UserFile,FileSize(UserFile));
  Write(UserFile,User);
  Close(UserFile);
  AddUser:=User.UserID;
 End;
End;

Function UpdateUser(Var User:UserRec):Boolean;
Var
 Pos:LongInt;
 UserFile:File of UserRec;
 CurrRec:UserRec;
Begin
 UpdateUser:=False;
 {$I-}Assign(UserFile,UserDataFile);
 Reset(UserFile);{$I+}
 If IOResult=0 Then Begin
  Pos:=0;
  Seek(UserFile,0);
  While Not EOF(UserFile)do Begin
   Read(UserFile,CurrRec);
   If(CurrRec.UserID=User.UserID)Then BEgin
    Seek(UserFile,Pos);
    Write(UserFile,User);
    UpdateUser:=True;
    Break;
   End;
   Inc(Pos);
  End;
  Close(UserFile);
 End;
End;

Function DeleteUser(UserID:LongInt):Boolean;
Var
 Pos:LongInt;
 UserFile:File of UserRec;
 CurrRec:UserRec;
Begin
 DeleteUser:=False;
 {$I-}Assign(UserFile,UserDataFile);
 Reset(UserFile);{$I+}
 If IOResult=0 Then Begin
  Pos:=0;
  Seek(UserFile,0);
  While Not EOF(UserFile)do Begin
   Read(UserFile,CurrRec);
   If(CurrRec.UserID=UserID)Then BEgin
    Seek(UserFile,Pos);
    CurrRec.UserID:=0;
    Write(UserFile,CurrRec);
    DeleteUser:=True;
    Break;
   End;
   Inc(Pos);
  End;
  Close(UserFile);
 End;
End;

Function ReadUser(UserID:LongInt;Var User:UserRec):Boolean;
Var
 UserFile:File of UserRec;
 CurrRec:UserRec;
Begin
 ReadUser:=False;
 {$I-}Assign(UserFile,UserDataFile);
 Reset(UserFile);{$I+}
 If IOResult=0 Then Begin
  Seek(UserFile,0);
  While Not EOF(UserFile)do Begin
   Read(UserFile,CurrRec);
   If(CurrRec.UserID=UserID)Then BEgin
    User:=CurrRec;
    ReadUser:=True;
    Break;
   End;
  End;
  Close(UserFile);
 End;
End;

Function AddProject(Var Project:ProjectRec):LongInt;
Var
 ProjectFile:File of ProjectRec;
Begin
 AddProject:=0;
 Project.ProjectID:=IncrementID(ProjectHeaderFile);
 {$I-}Assign(ProjectFile,ProjectDataFile);
 Reset(ProjectFile);
 If IOResult<>0 Then Rewrite(ProjectFile);{$I+}
 If IOResult=0 Then Begin
  Seek(ProjectFile,FileSize(ProjectFile));
  Write(ProjectFile,Project);
  Close(ProjectFile);
  AddProject:=Project.ProjectID;
 End;
End;

Function UpdateProject(Var Project:ProjectRec):Boolean;
Var
 Pos:LongInt;
 ProjectFile:File of ProjectRec;
 CurrRec:ProjectRec;
Begin
 UpdateProject:=False;
 {$I-}Assign(ProjectFile,ProjectDataFile);
 Reset(ProjectFile);{$I+}
 If IOResult=0 Then Begin
  Pos:=0;
  Seek(ProjectFile,0);
  While Not EOF(ProjectFile)do Begin
   Read(ProjectFile,CurrRec);
   If(CurrRec.ProjectID=Project.ProjectID)Then BEgin
    Seek(ProjectFile,Pos);
    Write(ProjectFile,Project);
    UpdateProject:=True;
    Break;
   End;
   Inc(Pos);
  End;
  Close(ProjectFile);
 End;
End;

Function DeleteProject(ProjectID:LongInt):Boolean;
Var
 Pos:LongInt;
 ProjectFile:File of ProjectRec;
 CurrRec:ProjectRec;
Begin
 DeleteProject:=False;
 {$I-}Assign(ProjectFile,ProjectDataFile);
 Reset(ProjectFile);{$I+}
 If IOResult=0 Then Begin
  Pos:=0;
  Seek(ProjectFile,0);
  While Not EOF(ProjectFile)do Begin
   Read(ProjectFile,CurrRec);
   If(CurrRec.ProjectID=ProjectID)Then BEgin
    Seek(ProjectFile,Pos);
    CurrRec.ProjectID:=0;
    Write(ProjectFile,CurrRec);
    DeleteProject:=True;
    Break;
   End;
   Inc(Pos);
  End;
  Close(ProjectFile);
 End;
End;

Function ReadProject(ProjectID:LongInt;Var Project:ProjectRec):Boolean;
Var
 ProjectFile:File of ProjectRec;
 CurrRec:ProjectRec;
Begin
 ReadProject:=False;
 {$I-}Assign(ProjectFile,ProjectDataFile);
 Reset(ProjectFile);{$I+}
 If IOResult=0 Then Begin
  Seek(ProjectFile,0);
  While Not EOF(ProjectFile)do Begin
   Read(ProjectFile,CurrRec);
   If(CurrRec.ProjectID=ProjectID)Then BEgin
    Project:=CurrRec;
    ReadProject:=True;
    Break;
   End;
  End;
  Close(ProjectFile);
 End;
End;

{$IFNDEF FPC}
 Procedure CursorOff;
 Var
  Regs:Registers;
 Begin
  Regs.AH:=1;
  Regs.CH:=32;
  Regs.CL:=0;
  Intr($10,Regs);
 End;

 Procedure CursorOn;
 Var
  Regs:Registers;
 Begin
  Regs.AX:=$0100;
  Regs.CX:=(7 shl 8)+9;
  Intr($10,Regs);
 End;
{$ENDIF}

Function DuplicateString(C:Char;Num:Integer):String;
Var
 I:Byte;
 S:String;
Begin
 S:='';
 For I:=1 to Num do S:=S+C;
 DuplicateString:=S;
End;

Procedure SetASCII128(X:Boolean);Begin
 ShowASCII128:=X;
End;

Function GetASCII128:Boolean;Begin
 GetASCII128:=ShowASCII128;
End;

Procedure Box(X1,Y1,X2,Y2,Couleur:Byte);Begin
 Window(X1,Y1,X2,Y2);
 TextBackground((Couleur shr 4)and 15);
 {$IFDEF FPC}
  If Couleur and $80=$80 Then Begin
   TextColor((Couleur and 15)+BLINK);
  End
   Else
  TextColor(Couleur and 15);
 {$ELSE}
  TextColor(Couleur and 15);
 {$ENDIF}
 ClrScr;
 Window(1,1,80,25);
End;

Procedure FrameEmpty(X1,Y1,X2,Y2,Couleur:Byte);
Var
 I:Byte;
 ChrHori,ChrVert:Char;
 Chr218,Chr192,Chr191,Chr217:Char;
Begin
 TextBackground((Couleur shr 4)and 15);
 {$IFDEF FPC}
  If Couleur and $80=$80 Then Begin
   TextColor((Couleur and 15)+BLINK);
  End
   Else
  TextColor(Couleur and 15);
 {$ELSE}
  TextColor(Couleur and 15);
 {$ENDIF}
 If(ShowASCII128)Then Begin
  ChrHori:='-';
  ChrVert:='|';
  Chr218:='+';
  Chr192:='+';
  Chr191:='+';
  Chr217:='+';
 End
  Else
 Begin
  ChrHori:=#$C4;
  ChrVert:=#$B3;
  Chr218:=#218;
  Chr192:=#192;
  Chr191:=#191;
  Chr217:=#217;
  End;
 For I:=Y1+1 to Y2-1 do Begin
  GotoXY(X1,I);
  Write(ChrVert);
  GotoXY(X2,I);
  Write(ChrVert);
 End;
 GotoXY(X1+1,Y1);
 Write(DuplicateString(ChrHori,X2-X1-1));
 GotoXY(X1+1,Y2);
 Write(DuplicateString(ChrHori,X2-X1-1));
 GotoXY(X1,Y1);
 Write(Chr218);
 GotoXY(X1,Y2);
 Write(Chr192);
 GotoXY(X2,Y1);
 Write(Chr191);
 GotoxY(X2,Y2);
 Write(Chr217);
End;

Procedure DialogBox(X1,Y1,X2,Y2,Couleur:Byte);Begin
 Box(X1,Y1,X2,Y2,Couleur);
 FrameEmpty(X1,Y1,X2,Y2,Couleur);
 TextAttr:=Couleur;
End;

Function ReadLine(Var S:String):Word;
Var
 Rec:SearchRec;
 K:Char;
 X,Y,I:Byte;
 CurrHistory:Integer;
Begin
 ReadLine:=0;
 X:=WhereX;
 Y:=WhereY;
 Repeat
  GotoXY(X,Y);
  Write(S);
  ClrEol;
  K:=ReadKey;
  Case K of
   #0:Case ReadKey of
    #72:Begin
     ReadLine:=kbUp;
     Exit;
    End;
    #80:Begin
     ReadLine:=kbDn;
     Exit;
    End;
   End;
   #8:Begin
    If S<>''Then S:=Copy(S,1,Length(S)-1);
   End;
   #9:Begin
    ReadLine:=kbTab;
    Exit;
   End;
   #13:Begin
    ReadLine:=kbEnter;
   End;
   #27:Begin
    ReadLine:=kbEsc;
    Exit;
   End;
   Else S:=S+K;
  End;
  If S[Length(S)]=#13Then Begin
   S:=Copy(S,1,Length(S)-1);
   K:=#13;
  End;
 Until K=#13;
 GotoXY(X,Y);
 WriteLn(S);
End;

Function ReadLineInBox(X1,Y1,X2,Y2:Byte;Var S:String):Word;Begin
 Window(X1,Y1,X2,Y2);
 ReadLineInBox:=ReadLine(S);
 Window(1,1,80,25);
End;

Procedure SetDialogTextColor;Begin
 TextBackground(CurrDialog shr 4);
 TextColor(CurrDialog and$F);
End;

Procedure SetButtonColor;Begin
 TextBackground(7);
 TextColor(0);
End;

Procedure SetSelectedButtonColor;Begin
 TextBackground(7);
 TextColor(13);
End;

Procedure ShowButton(ButtonList:String;PosButton:Byte);
Var
 I,CurrPosButton:Integer;
 First:Boolean;
 CurrButton:String;
Begin
 CurrButton:='';
 First:=True;
 CurrPosButton:=0;
 For I:=1 to Length(ButtonList)do Begin
  If ButtonList[I]='|'Then Begin
   SetDialogTextColor;
   If Not(First)Then Write('  ');
   If(PosButton=CurrPosButton)Then SetSelectedButtonColor
                              Else SetButtonColor;
   Write('  ',CurrButton,'  ');
   SetDialogTextColor;
   CurrButton:='';
   First:=False;
   Inc(CurrPosButton);
  End
   Else
  CurrButton:=CurrButton+ButtonList[I];
 End;
 SetDialogTextColor;
 If Not(First)Then Write('  ');
 If(PosButton=CurrPosButton)Then SetSelectedButtonColor
                            Else SetButtonColor;
 Write('  ',CurrButton,'  ');
End;

Function LengthButton(ButtonList:String):Integer;
Var
 I,CurrPosButton,LenButton:Integer;
 First:Boolean;
 CurrButton:String;
Begin
 LengthButton:=0;
 LenButton:=0;
 CurrButton:='';
 First:=True;
 CurrPosButton:=0;
 For I:=1 to Length(ButtonList)do Begin
  If ButtonList[I]='|'Then Begin
   If Not(First)Then Inc(LenButton,Length('  '));
   Inc(LenButton,Length('  '+CurrButton+'  '));
   CurrButton:='';
   First:=False;
   Inc(CurrPosButton);
  End
   Else
  CurrButton:=CurrButton+ButtonList[I];
 End;
 If Not(First)Then Inc(LenButton,Length('  '));
 Inc(LenButton,Length('  '+CurrButton+'  '));
 LengthButton:=LenButton;
End;

Function ReadHorizontalButton(ButtonList:String):Word;
Var
 X,Y:Byte;
 K:Char;
 I,NumButton,CurrButton:Integer;
Begin
 CurrDialog:=TextAttr;
 CursorOff;
 ReadHorizontalButton:=kbEsc;
 CurrButton:=0;
 NumButton:=1;
 X:=WhereX;
 Y:=WhereY;
 For I:=1 to Length(ButtonList)do If ButtonList[I]='|'Then Inc(NumButton);
 ShowButton(ButtonList,0);
 Repeat
  K:=ReadKey;
  Case K of
   #0:Case ReadKey of
    #15:Begin { Shift+Tab }
     If(CurrButton>0)Then Begin
      Dec(CurrButton);
      GotoXY(X,Y);
      ShowButton(ButtonList,CurrButton);
     End
      Else
     Begin
      ReadHorizontalButton:=kbShiftTab;
      Break;
     End;
    End;
    #75:Begin { Gauche }
     If(CurrButton>0)Then Dec(CurrButton)
                     Else CurrButton:=NumButton-1;
     GotoXY(X,Y);
     ShowButton(ButtonList,CurrButton);
    End;
    #77:Begin { Droite }
     If(CurrButton+1>=NumButton)Then CurrButton:=0
                                Else Inc(CurrButton);
     GotoXY(X,Y);
     ShowButton(ButtonList,CurrButton);
    End;
   End;
   #9:Begin
    If(CurrButton+1>=NumButton)Then Begin
     ReadHorizontalButton:=kbTab;
     Break;
    End
     Else
    Begin
     Inc(CurrButton);
     GotoXY(X,Y);
     ShowButton(ButtonList,CurrButton);
    End;
   End;
   #13:ReadHorizontalButton:=CurrButton;
   #27:ReadHorizontalButton:=kbEsc;
  End;
 Until K in[#13,#27];
 SetDialogTextColor;
 CursorOn;
End;

Procedure WriteCenter(Y:Byte;S:String;Color:Byte);Begin
 If S=''Then Exit;
 TextColor(Color and $F);
 TextBackground(Color shr 4);
 GotoXY(40-(Length(S) shr 1),Y);
 Write(S);
End;

Procedure ShowHorizontalCenterButton(Y:Byte;S:String);Begin
 GotoXY((80-LengthButton(S)) shr 1,Y);
 ShowButton(S,$FF);
End;

Function ReadHorizontalCenterButton(Y:Byte;S:String):Word;Begin
 GotoXY((80-LengthButton(S)) shr 1,Y);
 ReadHorizontalCenterButton:=ReadHorizontalButton(S);
End;

Procedure ErrorOk(Msg:String);
Var
 K:Word;
Begin
 CursorOff;
 DialogBox(11,10,71,17,$4F);
 WriteCenter(13,Msg,$40);
 K:=ReadHorizontalCenterButton(15,'Ok');
 CursorOn;
End;

Procedure DialogListBug;
Const
 MaxLine=12;
Var
 BugFile:File of BugRec;
 OldRec,CurrRec:BugRec;
 FP,MaxP:LongInt;
 Y:Byte;
 K:Char;

 Function ReadLine:Boolean;Begin
  ReadLine:=False;
  If(FP>=MaxP)Then Exit;
  Repeat
   {$I-}Seek(BugFile,FP);
   If(IOResult<>0)Then Exit;
   Inc(FP);
   Read(BugFile,CurrRec);{$I+}
   If(IOResult<>0)Then Exit;
  Until(CurrRec.BugId<>0);
  ReadLine:=True;
 End;

 Function ReadBackLine:Boolean;Begin
  ReadBackLine:=False;
  If(FP<=1)Then Exit;
  Repeat
   Dec(FP);
   {$I-}Seek(BugFile,FP-1);
   If(IOResult<>0)Then Exit;
   Read(BugFile,CurrRec);{$I+}
   If(IOResult<>0)Then Exit;
  Until(CurrRec.BugId<>0);
  ReadBackLine:=True;
 End;

 Procedure ShowLine(Y:Byte;Const CurrRec:BugRec);Begin
  GotoXY(7,10+Y);
  Write(CurrRec.BugID:8,' ',PadRight(Copy(CurrRec.Summary,1,40),58));
 End;

 Procedure ShowPtr;Begin
  TextBackground(Black);
  TextColor(LightCyan);
  GotoXY(6,10+Y);
  Write(#16);
  ShowLine(Y,CurrRec);
  OldRec:=CurrRec;
 End;

 Procedure HidePtr;Begin
  TextBackground(Cyan);
  TextColor(White);
  GotoXY(6,10+Y);
  Write(#32);
  ShowLine(Y,OldRec);
 End;

Begin
 {$I-}Assign(BugFile,BugDataFile);
 Reset(BugFile);{$I+}
 If IOResult=0 Then Begin
  CurrDialog:=$3F;
  DialogBox(5,6,75,23,$3F);
  WriteCenter(7,'Liste des bogues',$3F);
  GotoXY(7,9);
  TextColor(Yellow);
  Write('ID',' ':7,'Nom du bogue',' ':27,'Version');
  TextColor(White);
  FP:=0;MaxP:=FileSize(BugFile);
  For I:=0 to MaxLine do Begin
   If Not(ReadLine)Then Break;
   ShowLine(I,CurrRec);
  End;
  TextBackground(Blue);
  TextColor(LightCyan);
  GotoXY(1,25);
  Write(' Appuyer sur monter ou descendre ou presser, sur ESC pour retourner');
  ClrEol;
  TextBackground(Cyan);
  TextColor(White);
  FP:=0;
  Y:=0;
  ReadLine;
  ShowPtr;
  Repeat
   K:=ReadKey;
   Case K of
    #0:Case ReadKey of
     #72:Begin { Up }
      If Y>0Then Begin
       If(ReadBackLine)Then Begin
        HidePtr;
        Dec(Y);
        ShowPtr;
       End;
      End
       Else
      If(ReadBackLine)Then Begin
       HidePtr;
       Window(7,10,73,22);
       GotoXY(1,1);
       InsLine;
       Window(1,1,80,25);
       ShowLine(0,CurrRec);
       ShowPtr;
      End;
     End;
     #80:Begin { Down }
      If Y<MaxLine Then Begin
       If(ReadLine)Then Begin
        HidePtr;
        Inc(Y);
        ShowPtr;
       End;
      End
       Else
      Begin
       If(ReadLine)Then Begin
        HidePtr;
        Window(7,10,73,22);
        GotoXY(1,1);
        DelLine;
        Window(1,1,80,25);
        ShowLine(Y,CurrRec);
        ShowPtr;
       End;
      End;
     End;
    End;
    #27:Break;
   End;
  Until K=#27;
  Close(BugFile);
 End;
End;

Procedure DialogAddBug;
Var
 K:Word;
 Ok:Boolean;
 Bug:BugRec;
Begin
 FillChar(Bug,SizeOf(Bug),0);
 CurrDialog:=$3F;
 DialogBox(5,6,75,23,$3F);
 WriteCenter(7,'Ajouter un bogue',$3F);
 GotoXY(7,9);
 Write('Nom du bogue :');
 GotoXY(7,11);
 Write('Version :');
 Ok:=False;
 Repeat
  ShowHorizontalCenterButton(21,'Ajouter|Annuler');
  Repeat
   TextColor(White);
   TextBackground(Blue);
   K:=ReadLineInBox(25,9,72,9,Bug.Summary);
   If(K=kbEsc)Then Exit;
  Until(K=kbTab)or(K=kbEnter);
  Repeat
   TextColor(White);
   TextBackground(Blue);
   K:=ReadLineInBox(25,11,72,11,Bug.Description);
   If(K=kbEsc)Then Exit;
  Until(K=kbTab)or(K=kbEnter);
  TextColor(0);
  TextBackground(Cyan);
  K:=ReadHorizontalCenterButton(21,'Ajouter|Annuler');
  If(K=1)or(K=kbEsc)Then Exit;
  If(K=0)Then OK:=True;
 Until Ok;
 If AddBug(Bug)=0Then ErrorOk('Erreur d''ajout de bogue');
End;

Procedure DialogUpdateBug;
Var
 K,Err:Word;
 Ok:Boolean;
 Bug:BugRec;
 BugNumber:String;
Begin
 FillChar(Bug,SizeOf(Bug),0);
 DialogBox(5,10,75,17,$1F);
 WriteCenter(10,'Recherche le bogue',$1F);
 GotoXY(7,12);
 Write('Entrez le num‚ro de bogue :');
 Ok:=False;
 BugNumber:='';
 Repeat
  ShowHorizontalCenterButton(15,'Rechercher|Annuler');
  Repeat
   TextColor(White);
   TextBackground(Black);
   K:=ReadLineInBox(7,13,72,13,BugNumber);
   If(K=kbEsc)Then Exit;
  Until(K=kbTab)or(K=kbEnter);
  Val(BugNumber,Bug.BugID,Err);
  If Err<>0 Then ErrorOk('Num‚ro invalide !');
  TextColor(0);
  TextBackground(Cyan);
  K:=ReadHorizontalCenterButton(15,'Rechercher|Annuler');
  If(K=1)or(K=kbEsc)Then Exit;
  If(K=0)Then OK:=True;
 Until Ok;
 If ReadBug(Bug.BugID,Bug)Then Begin
  CurrDialog:=$3F;
  DialogBox(5,6,75,23,$3F);
  WriteCenter(7,'Modifier un bogue',$3F);
  GotoXY(7,9);
  Write('Sommaire :');
  GotoXY(25,9);
  Write(Bug.Summary);
  GotoXY(7,11);
  Write('Description :');
  GotoXY(25,11);
  Write(Bug.Description);
  Ok:=False;
  Repeat
   ShowHorizontalCenterButton(21,'Modifier|Annuler');
   Repeat
    TextColor(White);
    TextBackground(Blue);
    K:=ReadLineInBox(25,9,72,9,Bug.Summary);
    If(K=kbEsc)Then Exit;
   Until(K=kbTab)or(K=kbEnter);
   Repeat
    TextColor(White);
    TextBackground(Blue);
    K:=ReadLineInBox(25,11,72,11,Bug.Description);
    If(K=kbEsc)Then Exit;
   Until(K=kbTab)or(K=kbEnter);
   TextColor(0);
   TextBackground(Cyan);
   K:=ReadHorizontalCenterButton(21,'Modifier|Annuler');
   If(K=1)or(K=kbEsc)Then Exit;
   If(K=0)Then OK:=True;
  Until Ok;
  If Not UpdateBug(Bug)Then ErrorOk('Erreur de modification de bogue');
 End
  Else
 ErrorOk('Projet invalide !');
End;

Procedure DialogDeleteBug;
Var
 K,Err:Word;
 Ok:Boolean;
 BugID:LongInt;
 BugNumber:String;
Begin
 DialogBox(5,10,75,17,$4F);
 WriteCenter(10,'Supprimer le bogue',$4F);
 GotoXY(7,12);
 Write('Entrez le num‚ro de bogue :');
 Ok:=False;
 BugNumber:='';
 Repeat
  ShowHorizontalCenterButton(15,'Supprimer|Annuler');
  Repeat
   TextColor(White);
   TextBackground(Black);
   K:=ReadLineInBox(7,13,72,13,BugNumber);
   If(K=kbEsc)Then Exit;
  Until(K=kbTab)or(K=kbEnter);
  Val(BugNumber,BugID,Err);
  If Err<>0 Then ErrorOk('Num‚ro invalide !');
  TextColor(0);
  TextBackground(Cyan);
  K:=ReadHorizontalCenterButton(15,'Rechercher|Annuler');
  If(K=1)or(K=kbEsc)Then Exit;
  If(K=0)Then OK:=True;
 Until Ok;
 If Not DeleteBug(BugID)Then ErrorOk('Le bogue est introuvable !');
End;

Procedure DialogListProject;
Const
 MaxLine=12;
Var
 ProjectFile:File of ProjectRec;
 OldRec,CurrRec:ProjectRec;
 FP,MaxP:LongInt;
 Y:Byte;
 K:Char;

 Function ReadLine:Boolean;Begin
  ReadLine:=False;
  If(FP>=MaxP)Then Exit;
  Repeat
   {$I-}Seek(ProjectFile,FP);
   If(IOResult<>0)Then Exit;
   Inc(FP);
   Read(ProjectFile,CurrRec);{$I+}
   If(IOResult<>0)Then Exit;
  Until(CurrRec.ProjectId<>0);
  ReadLine:=True;
 End;

 Function ReadBackLine:Boolean;Begin
  ReadBackLine:=False;
  If(FP<=1)Then Exit;
  Repeat
   Dec(FP);
   {$I-}Seek(ProjectFile,FP-1);
   If(IOResult<>0)Then Exit;
   Read(ProjectFile,CurrRec);{$I+}
   If(IOResult<>0)Then Exit;
  Until(CurrRec.ProjectId<>0);
  ReadBackLine:=True;
 End;

 Procedure ShowLine(Y:Byte;Const CurrRec:ProjectRec);Begin
  GotoXY(7,10+Y);
  Write(CurrRec.ProjectID:8,' ',PadRight(Copy(CurrRec.Name,1,40),40),PadRight(Copy(CurrRec.Version,1,18),18));
 End;

 Procedure ShowPtr;Begin
  TextBackground(Black);
  TextColor(LightCyan);
  GotoXY(6,10+Y);
  Write(#16);
  ShowLine(Y,CurrRec);
  OldRec:=CurrRec;
 End;

 Procedure HidePtr;Begin
  TextBackground(Cyan);
  TextColor(White);
  GotoXY(6,10+Y);
  Write(#32);
  ShowLine(Y,OldRec);
 End;

Begin
 {$I-}Assign(ProjectFile,ProjectDataFile);
 Reset(ProjectFile);{$I+}
 If IOResult=0 Then Begin
  CurrDialog:=$3F;
  DialogBox(5,6,75,23,$3F);
  WriteCenter(7,'Liste des projets',$3F);
  GotoXY(7,9);
  TextColor(Yellow);
  Write('ID',' ':7,'Nom du projet',' ':27,'Version');
  TextColor(White);
  FP:=0;MaxP:=FileSize(ProjectFile);
  For I:=0 to MaxLine do Begin
   If Not(ReadLine)Then Break;
   ShowLine(I,CurrRec);
  End;
  TextBackground(Blue);
  TextColor(LightCyan);
  GotoXY(1,25);
  Write(' Appuyer sur monter ou descendre ou presser, sur ESC pour retourner');
  ClrEol;
  TextBackground(Cyan);
  TextColor(White);
  FP:=0;
  Y:=0;
  ReadLine;
  ShowPtr;
  Repeat
   K:=ReadKey;
   Case K of
    #0:Case ReadKey of
     #72:Begin { Up }
      If Y>0Then Begin
       If(ReadBackLine)Then Begin
        HidePtr;
        Dec(Y);
        ShowPtr;
       End;
      End
       Else
      If(ReadBackLine)Then Begin
       HidePtr;
       Window(7,10,73,22);
       GotoXY(1,1);
       InsLine;
       Window(1,1,80,25);
       ShowLine(0,CurrRec);
       ShowPtr;
      End;
     End;
     #80:Begin { Down }
      If Y<MaxLine Then Begin
       If(ReadLine)Then Begin
        HidePtr;
        Inc(Y);
        ShowPtr;
       End;
      End
       Else
      Begin
       If(ReadLine)Then Begin
        HidePtr;
        Window(7,10,73,22);
        GotoXY(1,1);
        DelLine;
        Window(1,1,80,25);
        ShowLine(Y,CurrRec);
        ShowPtr;
       End;
      End;
     End;
    End;
    #27:Break;
   End;
  Until K=#27;
  Close(ProjectFile);
 End;
End;

Procedure DialogAddProject;
Var
 K:Word;
 Ok:Boolean;
 Project:ProjectRec;
Begin
 FillChar(Project,SizeOf(Project),0);
 CurrDialog:=$3F;
 DialogBox(5,6,75,23,$3F);
 WriteCenter(7,'Ajouter un projet',$3F);
 GotoXY(7,9);
 Write('Nom du projet :');
 GotoXY(7,11);
 Write('Version :');
 Ok:=False;
 Repeat
  ShowHorizontalCenterButton(21,'Ajouter|Annuler');
  Repeat
   TextColor(White);
   TextBackground(Blue);
   K:=ReadLineInBox(25,9,72,9,Project.Name);
   If(K=kbEsc)Then Exit;
  Until(K=kbTab)or(K=kbEnter);
  Repeat
   TextColor(White);
   TextBackground(Blue);
   K:=ReadLineInBox(25,11,72,11,Project.Version);
   If(K=kbEsc)Then Exit;
  Until(K=kbTab)or(K=kbEnter);
  TextColor(0);
  TextBackground(Cyan);
  K:=ReadHorizontalCenterButton(21,'Ajouter|Annuler');
  If(K=1)or(K=kbEsc)Then Exit;
  If(K=0)Then OK:=True;
 Until Ok;
 If AddProject(Project)=0Then ErrorOk('Erreur d''ajout de projet');
End;

Procedure DialogUpdateProject;
Var
 K,Err:Word;
 Ok:Boolean;
 Project:ProjectRec;
 ProjectNumber:String;
Begin
 FillChar(Project,SizeOf(Project),0);
 DialogBox(5,10,75,17,$1F);
 WriteCenter(10,'Recherche le projet',$1F);
 GotoXY(7,12);
 Write('Entrez le num‚ro de projet :');
 Ok:=False;
 ProjectNumber:='';
 Repeat
  ShowHorizontalCenterButton(15,'Rechercher|Annuler');
  Repeat
   TextColor(White);
   TextBackground(Black);
   K:=ReadLineInBox(7,13,72,13,ProjectNumber);
   If(K=kbEsc)Then Exit;
  Until(K=kbTab)or(K=kbEnter);
  Val(ProjectNumber,Project.ProjectID,Err);
  If Err<>0 Then ErrorOk('Num‚ro invalide !');
  TextColor(0);
  TextBackground(Cyan);
  K:=ReadHorizontalCenterButton(15,'Rechercher|Annuler');
  If(K=1)or(K=kbEsc)Then Exit;
  If(K=0)Then OK:=True;
 Until Ok;
 If ReadProject(Project.ProjectID,Project)Then Begin
  CurrDialog:=$3F;
  DialogBox(5,6,75,23,$3F);
  WriteCenter(7,'Modifier un projet',$3F);
  GotoXY(7,9);
  Write('Nom du projet :');
  GotoXY(25,9);
  Write(Project.Name);
  GotoXY(7,11);
  Write('Version :');
  GotoXY(25,11);
  Write(Project.Version);
  Ok:=False;
  Repeat
   ShowHorizontalCenterButton(21,'Modifier|Annuler');
   Repeat
    TextColor(White);
    TextBackground(Blue);
    K:=ReadLineInBox(25,9,72,9,Project.Name);
    If(K=kbEsc)Then Exit;
   Until(K=kbTab)or(K=kbEnter);
   Repeat
    TextColor(White);
    TextBackground(Blue);
    K:=ReadLineInBox(25,11,72,11,Project.Version);
    If(K=kbEsc)Then Exit;
   Until(K=kbTab)or(K=kbEnter);
   TextColor(0);
   TextBackground(Cyan);
   K:=ReadHorizontalCenterButton(21,'Modifier|Annuler');
   If(K=1)or(K=kbEsc)Then Exit;
   If(K=0)Then OK:=True;
  Until Ok;
  If Not UpdateProject(Project)Then ErrorOk('Erreur de modification de projet');
 End
  Else
 ErrorOk('Projet invalide !');
End;

Procedure DialogDeleteProject;
Var
 K,Err:Word;
 Ok:Boolean;
 ProjectID:LongInt;
 ProjectNumber:String;
Begin
 DialogBox(5,10,75,17,$4F);
 WriteCenter(10,'Supprimer le projet',$4F);
 GotoXY(7,12);
 Write('Entrez le num‚ro de projet :');
 Ok:=False;
 ProjectNumber:='';
 Repeat
  ShowHorizontalCenterButton(15,'Supprimer|Annuler');
  Repeat
   TextColor(White);
   TextBackground(Black);
   K:=ReadLineInBox(7,13,72,13,ProjectNumber);
   If(K=kbEsc)Then Exit;
  Until(K=kbTab)or(K=kbEnter);
  Val(ProjectNumber,ProjectID,Err);
  If Err<>0 Then ErrorOk('Num‚ro invalide !');
  TextColor(0);
  TextBackground(Cyan);
  K:=ReadHorizontalCenterButton(15,'Rechercher|Annuler');
  If(K=1)or(K=kbEsc)Then Exit;
  If(K=0)Then OK:=True;
 Until Ok;
 If Not DeleteProject(ProjectID)Then ErrorOk('Le projet est introuvable !');
End;

Procedure DialogListUser;
Const
 MaxLine=12;
Var
 UserFile:File of UserRec;
 OldRec,CurrRec:UserRec;
 FP,MaxP:LongInt;
 Y:Byte;
 K:Char;

 Function ReadLine:Boolean;Begin
  ReadLine:=False;
  If(FP>=MaxP)Then Exit;
  Repeat
   {$I-}Seek(UserFile,FP);
   If(IOResult<>0)Then Exit;
   Inc(FP);
   Read(UserFile,CurrRec);{$I+}
   If(IOResult<>0)Then Exit;
  Until(CurrRec.UserId<>0);
  ReadLine:=True;
 End;

 Function ReadBackLine:Boolean;Begin
  ReadBackLine:=False;
  If(FP<=1)Then Exit;
  Repeat
   Dec(FP);
   {$I-}Seek(UserFile,FP-1);
   If(IOResult<>0)Then Exit;
   Read(UserFile,CurrRec);{$I+}
   If(IOResult<>0)Then Exit;
  Until(CurrRec.UserId<>0);
  ReadBackLine:=True;
 End;

 Procedure ShowLine(Y:Byte;Const CurrRec:UserRec);Begin
  GotoXY(7,10+Y);
  Write(CurrRec.UserID:8,' ',PadRight(Copy(CurrRec.FirstName,1,40),40),PadRight(Copy(CurrRec.LastName,1,18),18));
 End;

 Procedure ShowPtr;Begin
  TextBackground(Black);
  TextColor(LightCyan);
  GotoXY(6,10+Y);
  Write(#16);
  ShowLine(Y,CurrRec);
  OldRec:=CurrRec;
 End;

 Procedure HidePtr;Begin
  TextBackground(Cyan);
  TextColor(White);
  GotoXY(6,10+Y);
  Write(#32);
  ShowLine(Y,OldRec);
 End;

Begin
 {$I-}Assign(UserFile,UserDataFile);
 Reset(UserFile);{$I+}
 If IOResult=0 Then Begin
  CurrDialog:=$3F;
  DialogBox(5,6,75,23,$3F);
  WriteCenter(7,'Liste des projets',$3F);
  GotoXY(7,9);
  TextColor(Yellow);
  Write('ID',' ':7,'Nom du projet',' ':27,'Version');
  TextColor(White);
  FP:=0;MaxP:=FileSize(UserFile);
  For I:=0 to MaxLine do Begin
   If Not(ReadLine)Then Break;
   ShowLine(I,CurrRec);
  End;
  TextBackground(Blue);
  TextColor(LightCyan);
  GotoXY(1,25);
  Write(' Appuyer sur monter ou descendre ou presser, sur ESC pour retourner');
  ClrEol;
  TextBackground(Cyan);
  TextColor(White);
  FP:=0;
  Y:=0;
  ReadLine;
  ShowPtr;
  Repeat
   K:=ReadKey;
   Case K of
    #0:Case ReadKey of
     #72:Begin { Up }
      If Y>0Then Begin
       If(ReadBackLine)Then Begin
        HidePtr;
        Dec(Y);
        ShowPtr;
       End;
      End
       Else
      If(ReadBackLine)Then Begin
       HidePtr;
       Window(7,10,73,22);
       GotoXY(1,1);
       InsLine;
       Window(1,1,80,25);
       ShowLine(0,CurrRec);
       ShowPtr;
      End;
     End;
     #80:Begin { Down }
      If Y<MaxLine Then Begin
       If(ReadLine)Then Begin
        HidePtr;
        Inc(Y);
        ShowPtr;
       End;
      End
       Else
      Begin
       If(ReadLine)Then Begin
        HidePtr;
        Window(7,10,73,22);
        GotoXY(1,1);
        DelLine;
        Window(1,1,80,25);
        ShowLine(Y,CurrRec);
        ShowPtr;
       End;
      End;
     End;
    End;
    #27:Break;
   End;
  Until K=#27;
  Close(UserFile);
 End;
End;

Procedure DialogAddUser;
Var
 K:Word;
 Ok:Boolean;
 User:UserRec;
Begin
 FillChar(User,SizeOf(User),0);
 CurrDialog:=$3F;
 DialogBox(5,6,75,23,$3F);
 WriteCenter(7,'Ajouter un utilisateur',$3F);
 GotoXY(7,9);
 Write('Pr‚nom :');
 GotoXY(7,11);
 Write('Nom :');
 Ok:=False;
 Repeat
  ShowHorizontalCenterButton(21,'Ajouter|Annuler');
  Repeat
   TextColor(White);
   TextBackground(Blue);
   K:=ReadLineInBox(25,9,72,9,User.FirstName);
   If(K=kbEsc)Then Exit;
  Until(K=kbTab)or(K=kbEnter);
  Repeat
   TextColor(White);
   TextBackground(Blue);
   K:=ReadLineInBox(25,11,72,11,User.LastName);
   If(K=kbEsc)Then Exit;
  Until(K=kbTab)or(K=kbEnter);
  TextColor(0);
  TextBackground(Cyan);
  K:=ReadHorizontalCenterButton(21,'Ajouter|Annuler');
  If(K=1)or(K=kbEsc)Then Exit;
  If(K=0)Then OK:=True;
 Until Ok;
 If AddUser(User)=0Then ErrorOk('Erreur d''ajout de l''utilisateur');
End;

Procedure DialogUpdateUser;
Var
 K,Err:Word;
 Ok:Boolean;
 User:UserRec;
 UserNumber:String;
Begin
 FillChar(User,SizeOf(User),0);
 DialogBox(5,10,75,17,$1F);
 WriteCenter(10,'Recherche l''utilisateur',$1F);
 GotoXY(7,12);
 Write('Entrez le num‚ro de l''utilisateur :');
 Ok:=False;
 UserNumber:='';
 Repeat
  ShowHorizontalCenterButton(15,'Rechercher|Annuler');
  Repeat
   TextColor(White);
   TextBackground(Black);
   K:=ReadLineInBox(7,13,72,13,UserNumber);
   If(K=kbEsc)Then Exit;
  Until(K=kbTab)or(K=kbEnter);
  Val(UserNumber,User.UserID,Err);
  If Err<>0 Then ErrorOk('Num‚ro invalide !');
  TextColor(0);
  TextBackground(Cyan);
  K:=ReadHorizontalCenterButton(15,'Rechercher|Annuler');
  If(K=1)or(K=kbEsc)Then Exit;
  If(K=0)Then OK:=True;
 Until Ok;
 If ReadUser(User.UserID,User)Then Begin
  CurrDialog:=$3F;
  DialogBox(5,6,75,23,$3F);
  WriteCenter(7,'Modifier un utilisateur',$3F);
  GotoXY(7,9);
  Write('Pr‚nom :');
  GotoXY(25,9);
  Write(User.FirstName);
  GotoXY(7,11);
  Write('Nom :');
  GotoXY(25,11);
  Write(User.LastName);
  Ok:=False;
  Repeat
   ShowHorizontalCenterButton(21,'Modifier|Annuler');
   Repeat
    TextColor(White);
    TextBackground(Blue);
    K:=ReadLineInBox(25,9,72,9,User.FirstName);
    If(K=kbEsc)Then Exit;
   Until(K=kbTab)or(K=kbEnter);
   Repeat
    TextColor(White);
    TextBackground(Blue);
    K:=ReadLineInBox(25,11,72,11,User.LastName);
    If(K=kbEsc)Then Exit;
   Until(K=kbTab)or(K=kbEnter);
   TextColor(0);
   TextBackground(Cyan);
   K:=ReadHorizontalCenterButton(21,'Modifier|Annuler');
   If(K=1)or(K=kbEsc)Then Exit;
   If(K=0)Then OK:=True;
  Until Ok;
  If Not UpdateUser(User)Then ErrorOk('Erreur de modification de l''utilisateur');
 End
  Else
 ErrorOk('Projet invalide !');
End;

Procedure DialogDeleteUser;
Var
 K,Err:Word;
 Ok:Boolean;
 UserID:LongInt;
 UserNumber:String;
Begin
 DialogBox(5,10,75,17,$4F);
 WriteCenter(10,'Supprimer l''utilisateur',$4F);
 GotoXY(7,12);
 Write('Entrez le num‚ro de l''utilisateur :');
 Ok:=False;
 UserNumber:='';
 Repeat
  ShowHorizontalCenterButton(15,'Supprimer|Annuler');
  Repeat
   TextColor(White);
   TextBackground(Black);
   K:=ReadLineInBox(7,13,72,13,UserNumber);
   If(K=kbEsc)Then Exit;
  Until(K=kbTab)or(K=kbEnter);
  Val(UserNumber,UserID,Err);
  If Err<>0 Then ErrorOk('Num‚ro invalide !');
  TextColor(0);
  TextBackground(Cyan);
  K:=ReadHorizontalCenterButton(15,'Rechercher|Annuler');
  If(K=1)or(K=kbEsc)Then Exit;
  If(K=0)Then OK:=True;
 Until Ok;
 If Not DeleteUser(UserID)Then ErrorOk('L''utilisateur est introuvable !');
End;

Procedure InitApp;Begin
 CurrDialog:=TextAttr;
 {$I-}MkDir('DATA');{$I+}
 If IOResult<>0 Then Begin
 End;
End;

Procedure MainMenu;
Const
 MenuList:Array[0..12]of String[40]=(
  'A - Liste des bogues r‚pertori‚s',
  'B - Ajouter un bogue',
  'C - Mettre a jour un bogue',
  'D - Supprimer un bogue',
  'E - Liste des projets r‚pertori‚s',
  'F - Ajouter un projet',
  'G - Mettre a jour un projet',
  'H - Supprimer un projet',
  'I - Liste des utilisateurs r‚pertori‚s',
  'J - Ajouter un utilisateur',
  'K - Mettre a jour un utilisateur',
  'L - Supprimer un utilisateur',
  'Q - Quitter'
 );
Var
 I:Byte;
 K:Char;
Begin
 TextMode(CO80);
 TextBackground(LightGray);
 TextColor(Black);
 ClrScr;
 DialogBox(10,2,70,4,$1F);
 WriteCenter(3,'BUG-TRACKER',$1E);
 Repeat
  DialogBox(5,6,75,23,$3F);
  WriteCenter(7,'Sommaire',$3F);
  For I:=0 to 12 do Begin
   GotoXY(7,9+I);
   Write(MenuList[I]);
  End;
  K:=UpCase(ReadKey);
  Case K of
   'A':DialogListBug;
   'B':DialogAddBug;
   'C':DialogUpdateBug;
   'D':DialogDeleteBug;
   'E':DialogListProject;
   'F':DialogAddProject;
   'G':DialogUpdateProject;
   'H':DialogDeleteProject;
   'I':DialogListUser;
   'J':DialogAddUser;
   'K':DialogUpdateUser;
   'L':DialogDeleteUser;
   #27:Break;
  End;
 Until K='Q';
 TextColor(LightGray);
 TextBackground(Black);
 ClrScr;
End;

BEGIN
 {$IFDEF FPC}
  {$IFDEF WINDOWS}
   SetUseACP(False);
  {$ENDIF}
 {$ENDIF}
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')Then Begin
  WriteLn('BUGTRK : Cette commande permet de lancer l''application BugTracker.');
  WriteLn;
  WriteLn('Syntaxe : BUGTRK');
  WriteLn;
  WriteLn(' /ASCII128   Ce parametre permet de lancer en mode compatibilite 128 caracteres seulement.');
 End
  Else
 Begin
  ShowASCII128:=False;
  If ParamCount>0Then For I:=1 to ParamCount do Begin
   If StrToUpper(ParamStr(I))='/ASCII128'Then ShowASCII128:=True
    Else
   Begin
    WriteLn('Parametre inconnu : ',ParamStr(I));
    Halt;
   End;
  End;
  InitApp;
  MainMenu;
 End;
END.
