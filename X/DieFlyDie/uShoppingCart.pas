unit uShoppingCart;

interface

uses
  Classes, SysUtils, IWAppForm, IWApplication, IWTypes, frProductTree,
  frTopBar, Controls, Forms, IWBaseControl,
  IWControl, IWCompLabel, IWGrids, IWCompButton, IWVCLBaseControl,
  IWCompRectangle, IWHTMLControls, Graphics, IWCOlor, IWBaseHTMLControl;

type
  TISFShoppingCart = class(TIWAppForm)
    rectMain: TIWRectangle;
    rectLeft: TIWRectangle;
    rectTitle: TIWRectangle;
    lblShoppingCart: TIWLabel;
    grdItems: TIWGrid;
    lblTotal: TIWLabel;
    lnkUpdateCart: TIWLink;
    lnkFinalize: TIWLink;
    LeftTree: TISFProductTree;
    TopBar: TISFTopBar;
    procedure IWAppFormCreate(Sender: TObject);
    procedure lnkUpdateCartClick(Sender: TObject);
    procedure lnkFinalizeClick(Sender: TObject);
    procedure LeftTreelnkSourceClick(Sender: TObject);
  protected
     procedure LoadCart;
     function Validate : Boolean;
  public
  end;

implementation
{$R *.dfm}

uses
  DB,
  dmDieFlyDie,
  IWBaseForm, IWCompEdit, IWCompCheckBox,
  ServerController,
  uDisplayProduct, uDBInterface, uFinalize,
  uConstants; 

procedure TISFShoppingCart.IWAppFormCreate(Sender: TObject);
begin
  // Load the product tree
  LeftTree.LoadTree;

  // Load the cart
  LoadCart;
end;

procedure TISFShoppingCart.LoadCart;
var
  f, g : integer;
  LEdit : TIWEdit;
  LCheck : TIWCheckBox;
  LBigTotal : double;
begin
  LBigTotal := 0;

  with dmFly.qrShoppingCart, grdItems do
  begin
    Close;
{     SQL.Clear;
     SQL.Add('SELECT Quantity, ProductID, Name, Price');
     SQL.Add('FROM Cart, Products');
     SQL.Add('WHERE Products.ID = ProductID AND SessionID = :ASessionID');}
     ParamByName('ASessionID').AsString := UserSession.CartUserID;
     Open;

     RowCount := 1;

     Cell[0, 0].Width := '40%';
     Cell[0, 0].Text := 'Name';

     Cell[0, 1].Width := '15%';
     Cell[0, 1].Text := 'Quantity';

     Cell[0, 2].Width := '15%';
     Cell[0, 2].Text := 'Price per unit';

     Cell[0, 3].Width := '15%';
     Cell[0, 3].Text := 'Total price';

     Cell[0, 4].Width := '15%';
     Cell[0, 4].Text := 'Remove';

     for f := 0 to 4 do
     begin
        Cell[0, f].Font.Style := [fsBold];
        Cell[0, f].Alignment := taCenter;
        Cell[0, f].Height := IntToStr(lcHeaderCellHeight);
     end;

     f := 0;

     while not Eof do
     begin
        RowCount := RowCount + 1;
        Cell[f + 1, 0].Text := FieldByName('Name').AsString;
        Cell[f + 1, 0].Width := '40%';

        LEdit := TIWEdit.Create(Self);
        LEdit.Parent := Self;
        LEdit.Text := FieldByName('Quantity').AsString;
        LEdit.Tag := FieldByName('ProductID').AsInteger;
        LEdit.Alignment := taLeftJustify;
        LEdit.Width := 50;

        Cell[f + 1, 1].Control := LEdit;
        Cell[f + 1, 1].Alignment := taRightJustify;
        Cell[f + 1, 1].Width := '15%';

        Cell[f + 1, 2].Text := FormatFloat('###,###,###,##0.00', FieldByName('Price').AsFloat);
        Cell[f + 1, 2].Alignment := taRightJustify;
        Cell[f + 1, 2].Width := '15%';

        Cell[f + 1, 3].Text := FormatFloat('###,###,###,##0.00', FieldByName('Price').AsFloat * FieldByName('Quantity').AsInteger);
        Cell[f + 1, 3].Alignment := taRightJustify;
        Cell[f + 1, 3].Width := '15%';

        LBigTotal := LBigTotal + FieldByName('Price').AsFloat * FieldByName('Quantity').AsInteger;

        LCheck := TIWCheckBox.Create(Self);
        LCheck.Parent := Self;
        LCheck.Caption := '';
        LCheck.Tag := FieldByName('ProductID').AsInteger;
//        LCheck.Hint := 'Check this box then press -Update cart- to remove product.';
        Cell[f + 1, 4].Control := LCheck;
        Cell[f + 1, 4].Alignment := taCenter;
        Cell[f + 1, 4].Width := '15%';

        for g := 0 to 4 do
           Cell[f + 1, g].Height := IntToStr(lcCellHeight);

        f := f + 1;
        Next;
     end;
     Close;

     RowCount := RowCount + 1;
  end;

   // Set colors
  for f := 0 to Pred(grdItems.RowCount) do
     for g := 0 to 4 do
        if f in [0, Pred(grdItems.RowCount)] then
           grdItems.Cell[f, g].BGColor := lcHeaderColor
        else
           if f mod 2 = 0 then
              grdItems.Cell[f, g].BGColor := lcEvenColor
           else
              grdItems.Cell[f, g].BGColor := lcOddColor;

  lblTotal.Top := grdItems.Top + grdItems.RowCount * lcCellHeight + 10;
  lblTotal.Caption := Format(cTotalFormat, [FormatFloat('###,###,###,##0.00', LBigTotal)]);

  lnkUpdateCart.Top := lblTotal.Top + lblTotal.Height + 20;
  lnkFinalize.Top := lnkUpdateCart.Top;
end;

procedure TISFShoppingCart.lnkUpdateCartClick(Sender: TObject);
var
  f : integer;
begin
  if Validate then begin
    with dmFly.qrCart, grdItems do
    begin
       for f := 1 to RowCount - 2 do
       begin
          SQL.Clear;
          if TIWCheckBox(Cell[f, 4].Control).Checked then
          begin
             SQL.Add('DELETE FROM Cart');
             SQL.Add('WHERE SessionID = :ASessionID AND ProductID = :AProductID');
             ParamByName('ASessionID').AsString := UserSession.CartUserID;
             ParamByName('AProductID').AsInteger := TIWCheckBox(Cell[f, 4].Control).Tag;
             ExecSQL;
          end
          else
          begin
             SQL.Add('UPDATE Cart SET Quantity = :AQuantity');
             SQL.Add('WHERE SessionID = :ASessionID AND ProductID = :AProductID');
             ParamByName('ASessionID').AsString := UserSession.CartUserID;
             ParamByName('AProductID').AsInteger := TIWCheckBox(Cell[f, 4].Control).Tag;
             ParamByName('AQuantity').AsString := TIWEdit(Cell[f, 1].Control).Text;
             ExecSQL;
          end;
       end;
    end;

    LoadCart;
  end;
end;

procedure TISFShoppingCart.lnkFinalizeClick(Sender: TObject);
begin
  if grdItems.RowCount = 2 then                         // no item in the shopping cart
    begin
      WebApplication.ShowMessage('Please add items to the shopping cart');
    end
  else
    begin
      if not UserSession.LoggedIn then
         UserSession.NeedLogin(TISFFinalize)
      else
      begin
         TIWAppForm(WebApplication.ActiveForm).Release;
         TISFFinalize.Create(WebApplication).Show;
      end;
    end;
end;
       
procedure TISFShoppingCart.LeftTreelnkSourceClick(Sender: TObject);
begin
  LeftTree.lnkSourceClick(Sender);
end;

function TISFShoppingCart.Validate : Boolean;
var
  LIndex : Integer;
begin
  Result := true;
  for LIndex := 1 to grdItems.RowCount - 2 do begin      // skip the header and the footer
    try
      StrToInt(TIWEdit(grdItems.Cell[LIndex, 1].Control).Text);
    except
      Result := false;
      TIWEdit(grdItems.Cell[LIndex, 1].Control).Text := '1';
    end;
  end;
end;

end.
