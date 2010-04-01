//---------------------------------------------------------------------------

#include <vcl.h>
#pragma hdrstop

#include "selecttype.h"
#include "mainform.h"
//---------------------------------------------------------------------------
#pragma package(smart_init)
#pragma resource "*.dfm"
TTypeSelect *TypeSelect;
//---------------------------------------------------------------------------
__fastcall TTypeSelect::TTypeSelect(TComponent* Owner)
  : TForm(Owner)
{
}
//---------------------------------------------------------------------------
void __fastcall TTypeSelect::FormShow(TObject *Sender)
{
  ComboBox1->Items->Clear();
  for(int i=0; i<Main->CheckListBox2->Items->Count; i++)
    ComboBox1->Items->Add(Main->CheckListBox2->Items->Strings[i]);
  ComboBox1->ItemIndex = 0;
  Button2->SetFocus();
}
//---------------------------------------------------------------------------
