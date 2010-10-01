//---------------------------------------------------------------------------

#ifndef selecttypeH
#define selecttypeH
//---------------------------------------------------------------------------
#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
//---------------------------------------------------------------------------
class TTypeSelect : public TForm
{
__published:	// Composants g�r�s par l'EDI
  TComboBox *ComboBox1;
  TLabel *Label1;
  TButton *Button1;
  TButton *Button2;
  void __fastcall FormShow(TObject *Sender);
private:	// D�clarations de l'utilisateur
public:		// D�clarations de l'utilisateur
  __fastcall TTypeSelect(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern PACKAGE TTypeSelect *TypeSelect;
//---------------------------------------------------------------------------
#endif
