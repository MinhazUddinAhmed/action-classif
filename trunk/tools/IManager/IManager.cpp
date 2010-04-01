//---------------------------------------------------------------------------

#include <vcl.h>
#pragma hdrstop
//---------------------------------------------------------------------------
USEFORM("Mainform.cpp", Main);
USEFORM("params.cpp", Parameters);
USEFORM("..\IFilter\actionform.cpp", Actions);
USEFORM("selecttype.cpp", TypeSelect);
//---------------------------------------------------------------------------
WINAPI WinMain(HINSTANCE, HINSTANCE, LPSTR, int)
{
  try
  {
     Application->Initialize();
     Application->CreateForm(__classid(TMain), &Main);
     Application->CreateForm(__classid(TParameters), &Parameters);
     Application->CreateForm(__classid(TActions), &Actions);
     Application->CreateForm(__classid(TTypeSelect), &TypeSelect);
     Application->Run();
  }
  catch (Exception &exception)
  {
     Application->ShowException(&exception);
  }
  catch (...)
  {
     try
     {
       throw Exception("");
     }
     catch (Exception &exception)
     {
       Application->ShowException(&exception);
     }
  }
  return 0;
}
//---------------------------------------------------------------------------
