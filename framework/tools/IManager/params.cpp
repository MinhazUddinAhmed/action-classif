//---------------------------------------------------------------------------

#include <vcl.h>
#include <FileCtrl.hpp>
#include <Dialogs.hpp>

#pragma hdrstop

#include "../common/utils.h"
#include "params.h"
#include "mainform.h"
//---------------------------------------------------------------------------
#pragma package(smart_init)
#pragma resource "*.dfm"
TParameters *Parameters;
//---------------------------------------------------------------------------
__fastcall TParameters::TParameters(TComponent* Owner)
  : TForm(Owner)
{
}
//---------------------------------------------------------------------------
void __fastcall TParameters::FormShow(TObject *Sender)
{
  ShowParams();
  VerifOK();
}
//---------------------------------------------------------------------------
void TParameters::ShowParams()
{
  LabeledEdit1->Text = Main->ImageFolder.c_str();
  LabeledEdit2->Text = Main->AnnotFolder.c_str();
  Edit1->Text = IntToStr(Main->next_img);
}
//---------------------------------------------------------------------------
void TParameters::VerifOK()
{
  Button3->Enabled = (LabeledEdit1->Text != "") && (LabeledEdit2->Text != "");
}
//---------------------------------------------------------------------------
void __fastcall TParameters::Button1Click(TObject *Sender)
{
  AnsiString Dir;
  if(LabeledEdit1->Text == "")
    Dir = GetDirName(Application->ExeName.c_str()).c_str();
  else
    Dir = LabeledEdit1->Text;
  if(SelectDirectory(Dir, TSelectDirOpts(),0))
    LabeledEdit1->Text = Dir;
}
//---------------------------------------------------------------------------
void __fastcall TParameters::Button2Click(TObject *Sender)
{
  AnsiString Dir;
  if(LabeledEdit2->Text == "")
    Dir = GetDirName(Application->ExeName.c_str()).c_str();
  else
    Dir = LabeledEdit2->Text;
  if(SelectDirectory(Dir, TSelectDirOpts(),0))
    LabeledEdit2->Text = Dir;
}
//---------------------------------------------------------------------------
void __fastcall TParameters::ListBox1Click(TObject *Sender)
{
  VerifOK();
}
//---------------------------------------------------------------------------
void __fastcall TParameters::LabeledEdit1Change(TObject *Sender)
{
  VerifOK();
}
//---------------------------------------------------------------------------
void __fastcall TParameters::LabeledEdit2Change(TObject *Sender)
{
  VerifOK();
}
//---------------------------------------------------------------------------
void __fastcall TParameters::Button3Click(TObject *Sender)
{
  if(!DirectoryExists(LabeledEdit1->Text))
  {
    if(Application->MessageBox("The image directory doesn't exist. Do you want to create it?", "Image directory", MB_YESNO|MB_ICONEXCLAMATION) == IDYES)
      MakeFullDir(LabeledEdit1->Text.c_str());
    else
    {
      ModalResult = mrNone;
      return;
    }
  }
  if(!DirectoryExists(LabeledEdit2->Text))
  {
    if(Application->MessageBox("The annotation directory doesn't exist. Do you want to create it?", "Image directory", MB_YESNO|MB_ICONEXCLAMATION) == IDYES)
      MakeFullDir(LabeledEdit2->Text.c_str());
    else
    {
      ModalResult = mrNone;
      return;
    }
  }
  Main->ImageFolder = LabeledEdit1->Text.c_str();
  Main->AnnotFolder = LabeledEdit2->Text.c_str();
  Main->next_img = StrToInt(Edit1->Text);
  Main->SaveParam();
}
//---------------------------------------------------------------------------

