{-----------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/MPL-1.1.html

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either expressed or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: JvComCtrls.PAS, released Oct 10, 1999.

The Initial Developer of the Original Code is Petr Vones (petr.v@mujmail.cz)
Portions created by Petr Vones are Copyright (C) 1999 Petr Vones.
Portions created by Microsoft are Copyright (C) 1998, 1999 Microsoft Corp.
All Rights Reserved.

Contributor(s):
Peter Below [100113.1101@compuserve.com] - alternate TJvPageControl.OwnerDraw routine
Peter Th�rnqvist [peter3@peter3.com] added TJvIPAddress.AddressValues and TJvPageControl.ReduceMemoryUse
Alfi [alioscia_alessi@onde.net] alternate TJvPageControl.OwnerDraw routine
Rudy Velthuis - ShowRange in TJvTrackBar

Last Modified: 2002-06-27
Current Version: 0.50

You may retrieve the latest version of this file at the Project JEDI's JVCL home page,
located at http://jvcl.sourceforge.net

Known Issues:
  TJvTreeView:
    When dragging an item and MultiSelect is True droptarget node is not painted
    correctly.
  TJvIpAddress:
    Can't focus next control by TAB key on D4.
-----------------------------------------------------------------------------}

{$I jvcl.inc}
{$I windowsonly.inc}

unit JvComCtrls;

interface

uses
  Windows, Messages, SysUtils, Contnrs, Graphics, Controls, Forms, Dialogs, 
  Classes, // (ahuser) "Classes" after "Forms" due to D5 warnings
  Menus, ComCtrls, CommCtrl, StdActns,
  JclBase,
  JvComponent, JvExControls, JvExComCtrls;

const
  JvDefPageControlBorder = 4;
  TVM_SETLINECOLOR = TV_FIRST + 40;
  TVM_GETLINECOLOR = TV_FIRST + 41;
  {$IFDEF BCB6}
  {$EXTERNALSYM TVM_SETLINECOLOR}
  {$EXTERNALSYM TVM_GETLINECOLOR}
  {$ENDIF BCB6}

type
  TJvIPAddress = class;

  TJvIPAddressMinMax = record
    Min: Byte;
    Max: Byte;
  end;

  TJvIPEditControlHelper = class(TObject)
  private
    FHandle: THandle;
    FInstance: Pointer;
    FIPAddress: TJvIPAddress;
    FOrgWndProc: Pointer;
    procedure SetHandle(const Value: THandle);
  protected
    procedure WndProc(var Msg: TMessage); virtual;
    property Handle: THandle read FHandle write SetHandle;
  public
    constructor Create(AIPAddress: TJvIPAddress);
    destructor Destroy; override;

    procedure DefaultHandler(var Msg); override;
  end;

  TJvIPAddressRange = class(TPersistent)
  private
    FControl: TWinControl;
    FRange: array [0..3] of TJvIPAddressMinMax;
    function GetMaxRange(Index: Integer): Byte;
    function GetMinRange(Index: Integer): Byte;
    procedure SetMaxRange(const Index: Integer; const Value: Byte);
    procedure SetMinRange(const Index: Integer; const Value: Byte);
  protected
    procedure AssignTo(Dest: TPersistent); override;
    procedure Change(Index: Integer);
  public
    constructor Create(Control: TWinControl);
  published
    property Field1Min: Byte index 0 read GetMinRange write SetMinRange default 0;
    property Field1Max: Byte index 0 read GetMaxRange write SetMaxRange default 255;
    property Field2Min: Byte index 1 read GetMinRange write SetMinRange default 0;
    property Field2Max: Byte index 1 read GetMaxRange write SetMaxRange default 255;
    property Field3Min: Byte index 2 read GetMinRange write SetMinRange default 0;
    property Field3Max: Byte index 2 read GetMaxRange write SetMaxRange default 255;
    property Field4Min: Byte index 3 read GetMinRange write SetMinRange default 0;
    property Field4Max: Byte index 3 read GetMaxRange write SetMaxRange default 255;
  end;

  TJvIpAddrFieldChangeEvent = procedure(Sender: TJvIPAddress; FieldIndex: Integer;
    FieldRange: TJvIPAddressMinMax; var Value: Integer) of object;
  TJvIPAddressChanging = procedure(Sender: TObject; Index: Integer; Value: Byte; var AllowChange: Boolean) of object;

  TJvIPAddressValues = class(TPersistent)
  private
    FValues: array [0..3] of Byte;
    FOnChange: TNotifyEvent;
    FOnChanging: TJvIPAddressChanging;
    function GetValue: Cardinal;
    procedure SetValue(const AValue: Cardinal);
    procedure SetValues(Index: Integer; Value: Byte);
    function GetValues(Index: Integer): Byte;
  protected
    procedure Change; virtual;
    function Changing(Index: Integer; Value: Byte): Boolean; virtual;
  public
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnChanging: TJvIPAddressChanging read FOnChanging write FOnChanging;
  published
    property Address: Cardinal read GetValue write SetValue;
    property Value1: Byte index 0 read GetValues write SetValues;
    property Value2: Byte index 1 read GetValues write SetValues;
    property Value3: Byte index 2 read GetValues write SetValues;
    property Value4: Byte index 3 read GetValues write SetValues;
  end;

  TJvIPAddress = class(TJvWinControl)
  private
    FEditControls: array[0..3] of TJvIPEditControlHelper;
    FEditControlCount: Integer;
    FAddress: LongWord;
    FChanging: Boolean;
    FRange: TJvIPAddressRange;
    FAddressValues: TJvIPAddressValues;
    FSaveBlank: Boolean;
    FOnFieldChange: TJvIpAddrFieldChangeEvent;
    LocalFont: HFONT;
    FOnChange: TNotifyEvent;
    procedure ClearEditControls;
    procedure DestroyLocalFont;
    procedure SetAddress(const Value: LongWord);
    procedure CNCommand(var Msg: TWMCommand); message CN_COMMAND;
    procedure CNNotify(var Msg: TWMNotify); message CN_NOTIFY;
    procedure WMDestroy(var Msg: TWMNCDestroy); message WM_DESTROY;
    procedure WMParentNotify(var Msg: TWMParentNotify); message WM_PARENTNOTIFY;
    procedure WMSetFont(var Msg: TWMSetFont); message WM_SETFONT;
    procedure SetAddressValues(const Value: TJvIPAddressValues);
  protected
    procedure DoGetDlgCode(var Code: TDlgCodes); override;
    procedure EnabledChanged; override;
    procedure ColorChanged; override;
    procedure FontChanged; override;
    function DoPaintBackground(Canvas: TCanvas; Param: Integer): Boolean; override;
    procedure AdjustHeight;
    procedure AdjustSize; override;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure CreateWnd; override;
    procedure DestroyWnd; override;
    procedure DoChange; dynamic;

    procedure DoAddressChange(Sender: TObject); virtual;
    procedure DoAddressChanging(Sender: TObject; Index: Integer;
      Value: Byte; var AllowChange: Boolean); virtual;
    procedure DoFieldChange(FieldIndex: Integer; var FieldValue: Integer); dynamic;
    procedure TextChanged; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure ClearAddress;
    function IsBlank: Boolean;
    property Text;
  published
    property Address: LongWord read FAddress write SetAddress default 0;
    property AddressValues: TJvIPAddressValues read FAddressValues write SetAddressValues;
    property Anchors;
    property Constraints;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property Range: TJvIPAddressRange read FRange write FRange;
    property ShowHint;
    property TabOrder;
    property TabStop default True;
    property Visible;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnContextPopup;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnFieldChange: TJvIpAddrFieldChangeEvent read FOnFieldChange write FOnFieldChange;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnStartDock;
    property OnStartDrag;
  end;

  // TJvHintSource is a hint enumeration type to describe how to display hints for
  // controls that have hint properties both for the main control as well as
  // for it's subitems (like a PageControl)
  // TODO: (p3) this should really be moved to JvTypes or something...
  TJvHintSource =
   (
    hsDefault, // use default hint behaviour (i.e as regular control)
    hsForceMain, // use the main hint even if subitems have hints
    hsForceChildren, // always use subitems hints even if empty
    hsPreferMain, // use main control hint unless empty then use subitems hints
    hsPreferChildren // use subitems hints unless empty then use main control hint
   );

  TJvPageControl = class(TJvExPageControl)
  private
    FClientBorderWidth: TBorderWidth;
    FHideAllTabs: Boolean;
    FColor: TColor;
    FSaved: TColor;
    FOnParentColorChanged: TNotifyEvent;
    FDrawTabShadow: Boolean;
    FHandleGlobalTab: Boolean;
    FHintSource: TJvHintSource;
    FReduceMemoryUse: Boolean;
    procedure SetClientBorderWidth(const Value: TBorderWidth);
    procedure TCMAdjustRect(var Msg: TMessage); message TCM_ADJUSTRECT;
    procedure WMLButtonDown(var Msg: TWMLButtonDown); message WM_LBUTTONDOWN;
    procedure SetDrawTabShadow(const Value: Boolean);
    procedure SetHideAllTabs(const Value: Boolean);
    function FormKeyPreview: Boolean;
    procedure SetReduceMemoryUse(const Value: Boolean);
  protected
    procedure MouseEnter(Control: TControl); override;
    procedure MouseLeave(Control: TControl); override;
    procedure ParentColorChanged; override;
    function HintShow(var HintInfo: THintInfo): Boolean; override;
    function WantKey(Key: Integer; Shift: TShiftState;
      const KeyText: WideString): Boolean; override;

    procedure Loaded; override;
    procedure DrawDefaultTab(TabIndex: Integer; const Rect: TRect; Active: Boolean; DefaultDraw: Boolean);
    procedure DrawShadowTab(TabIndex: Integer; const Rect: TRect; Active: Boolean; DefaultDraw: Boolean);
    procedure DrawTab(TabIndex: Integer; const Rect: TRect; Active: Boolean); override;
    function CanChange: Boolean; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure UpdateTabImages;
  published
    property HintSource: TJvHintSource read FHintSource write FHintSource default hsDefault;
    property HandleGlobalTab: Boolean read FHandleGlobalTab write FHandleGlobalTab default False;
    property ClientBorderWidth: TBorderWidth read FClientBorderWidth write SetClientBorderWidth default
      JvDefPageControlBorder;
    property ReduceMemoryUse: Boolean read FReduceMemoryUse write SetReduceMemoryUse default False;
    property DrawTabShadow: Boolean read FDrawTabShadow write SetDrawTabShadow default False;
    property HideAllTabs: Boolean read FHideAllTabs write SetHideAllTabs default False;
    property HintColor: TColor read FColor write FColor default clInfoBk;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnParentColorChange: TNotifyEvent read FOnParentColorChanged write FOnParentColorChanged;
    property Color;
  end;

  TJvTrackToolTipSide = (tsLeft, tsTop, tsRight, tsBottom);
  TJvTrackToolTipEvent = procedure(Sender: TObject; var ToolTipText: string) of object;

  TJvTrackBar = class(TJvExTrackBar)
  private
    FToolTips: Boolean;
    FToolTipSide: TJvTrackToolTipSide;
    FToolTipText: WideString;
    FOnToolTip: TJvTrackToolTipEvent;
    FColor: TColor;
    FSaved: TColor;
    FOnParentColorChanged: TNotifyEvent;
    FOnChanged: TNotifyEvent;
    FShowRange: Boolean;
    procedure SetToolTips(const Value: Boolean);
    procedure SetToolTipSide(const Value: TJvTrackToolTipSide);
    procedure WMNotify(var Msg: TWMNotify); message WM_NOTIFY;
    procedure CNHScroll(var Msg: TWMHScroll); message CN_HSCROLL;
    procedure CNVScroll(var Msg: TWMVScroll); message CN_VSCROLL;
    procedure SetShowRange(const Value: Boolean);
  protected
    procedure MouseEnter(Control: TControl); override;
    procedure MouseLeave(Control: TControl); override;
    procedure ParentColorChanged; override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure CreateWnd; override;
    procedure InternalSetToolTipSide;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property ShowRange: Boolean read FShowRange write SetShowRange default True;
    property ToolTips: Boolean read FToolTips write SetToolTips default False;
    property ToolTipSide: TJvTrackToolTipSide read FToolTipSide write SetToolTipSide default tsLeft;
    property HintColor: TColor read FColor write FColor default clInfoBk;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnParentColorChange: TNotifyEvent read FOnParentColorChanged write FOnParentColorChanged;
    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;
    property Color;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnToolTip: TJvTrackToolTipEvent read FOnToolTip write FOnToolTip;
  end;

  TJvTreeNode = class(TTreeNode)
  private
    FBold: Boolean;
    FChecked: Boolean;
    FPopupMenu: TPopupMenu;
    function GetChecked: Boolean;
    procedure SetChecked(Value: Boolean);
    function GetBold: Boolean;
    procedure SetBold(const Value: Boolean);
    procedure SetPopupMenu(const Value: TPopupMenu);
  public
    class function CreateEnh(AOwner: TTreeNodes): TJvTreeNode;
    property Checked: Boolean read GetChecked write SetChecked;
    property Bold: Boolean read GetBold write SetBold;
    property PopupMenu: TPopupMenu read FPopupMenu write SetPopupMenu;
  end;

  TPageChangedEvent = procedure(Sender: TObject; Item: TTreeNode; Page: TTabSheet) of object;
  TJvTreeViewComparePageEvent = procedure(Sender: TObject; Page: TTabSheet;
    Node: TTreeNode; var Matches: Boolean) of object;

  TJvTreeView = class(TJvExTreeView)
  private
    FAutoDragScroll: Boolean;
    FClearBeforeSelect: Boolean;
    FMultiSelect: Boolean;
    FScrollDirection: Integer;
    FSelectedList: TObjectList;
    FSelectThisNode: Boolean;
    FOnCustomDrawItem: TTVCustomDrawItemEvent;
    FOnEditCancelled: TNotifyEvent;
    FOnSelectionChange: TNotifyEvent;
    FColor: TColor;
    FSaved: TColor;
    FOnParentColorChanged: TNotifyEvent;
    FOver: Boolean;
    FCheckBoxes: Boolean;
    FOnHScroll: TNotifyEvent;
    FOnVScroll: TNotifyEvent;
    FPageControl: TPageControl;
    FOnPage: TPageChangedEvent;
    FOnComparePage: TJvTreeViewComparePageEvent;
    procedure InternalCustomDrawItem(Sender: TCustomTreeView;
      Node: TTreeNode; State: TCustomDrawState; var DefaultDraw: Boolean);
    function GetSelectedCount: Integer;
    function GetSelectedItem(Index: Integer): TTreeNode;
    {$IFNDEF COMPILER6_UP}
    procedure SetMultiSelect(const Value: Boolean);
    {$ENDIF COMPILER6_UP}
    procedure SetScrollDirection(const Value: Integer);
    procedure WMLButtonDown(var Msg: TWMLButtonDown); message WM_LBUTTONDOWN;
    procedure WMTimer(var Msg: TWMTimer); message WM_TIMER;
    procedure WMHScroll(var Msg: TWMHScroll); message WM_HSCROLL;
    procedure WMVScroll(var Msg: TWMVScroll); message WM_VSCROLL;
    procedure SetCheckBoxes(const Value: Boolean);
    function GetItemHeight: Integer;
    procedure SetItemHeight(Value: Integer);
    function GetInsertMarkColor: TColor;
    procedure SetInsertMarkColor(Value: TColor);
    function GetLineColor: TColor;
    procedure SetLineColor(Value: TColor);
    function GetMaxScrollTime: Integer;
    procedure SetMaxScrollTime(const Value: Integer);
    function GetUseUnicode: Boolean;
    procedure SetUseUnicode(const Value: Boolean);
  protected
    procedure MouseEnter(Control: TControl); override;
    procedure MouseLeave(Control: TControl); override;
    procedure ParentColorChanged; override;
    function DoComparePage(Page: TTabSheet; Node: TTreeNode): Boolean; virtual;
    function CreateNode: TTreeNode; override;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure WMNotify(var Msg: TWMNotify); message CN_NOTIFY;

    procedure Change(Node: TTreeNode); override;
    procedure Delete(Node: TTreeNode); override;
    procedure DoEditCancelled; dynamic;
    procedure DoEnter; override;
    procedure DoExit; override;
    procedure DoEndDrag(Target: TObject; X, Y: Integer); override;
    procedure DoSelectionChange; dynamic;
    procedure DragOver(Source: TObject; X, Y: Integer; State: TDragState;
      var Accept: Boolean); override;
    procedure Edit(const Item: TTVItem); override;
    procedure InvalidateNode(Node: TTreeNode);
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;
    procedure ResetPostOperationFlags;
    property ScrollDirection: Integer read FScrollDirection write SetScrollDirection;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure ClearSelection; reintroduce;
    function IsNodeSelected(Node: TTreeNode): Boolean;
    procedure InvalidateNodeIcon(Node: TTreeNode);
    procedure InvalidateSelectedItems;
    procedure SelectItem(Node: TTreeNode; Unselect: Boolean = False);
    property SelectedItems[Index: Integer]: TTreeNode read GetSelectedItem;
    property SelectedCount: Integer read GetSelectedCount;
    function GetBold(Node: TTreeNode): Boolean;
    procedure SetBold(Node: TTreeNode; Value: Boolean);
    function GetChecked(Node: TTreenode): Boolean;
    procedure SetChecked(Node: TTreenode; Value: Boolean);
    procedure SetNodePopup(Node: TTreeNode; Value: TPopupMenu);
    function GetNodePopup(Node: TTreeNode): TPopupMenu;
    procedure InsertMark(Node: TTreeNode; MarkAfter: Boolean); // TVM_SETINSERTMARK
    procedure RemoveMark;
    property InsertMarkColor: TColor read GetInsertMarkColor write SetInsertMarkColor;
    property Checked[Node: TTreeNode]: Boolean read GetChecked write SetChecked;
    property MaxScrollTime: Integer read GetMaxScrollTime write SetMaxScrollTime;
    // UseUnicode should only be changed on Win95 and Win98 that has IE5 or later installed
    property UseUnicode: Boolean read GetUseUnicode write SetUseUnicode default False;
  published
    property LineColor: TColor read GetLineColor write SetLineColor default clDefault;
    property ItemHeight: Integer read GetItemHeight write SetItemHeight default 16;

    property HintColor: TColor read FColor write FColor default clInfoBk;

    property Checkboxes: Boolean read FCheckBoxes write SetCheckBoxes default False;
    property OnVerticalScroll: TNotifyEvent read FOnVScroll write FOnVScroll;
    property OnHorizontalScroll: TNotifyEvent read FOnHScroll write FOnHScroll;
    property PageControl: TPageControl read FPageControl write FPageControl;
    property OnPageChanged: TPageChangedEvent read FOnPage write FOnPage;

    property AutoDragScroll: Boolean read FAutoDragScroll write FAutoDragScroll default False;
    {$IFNDEF COMPILER6_UP}
    property MultiSelect: Boolean read FMultiSelect write SetMultiSelect default False;
    {$ENDIF COMPILER6_UP}
    property OnComparePage: TJvTreeViewComparePageEvent read FOnComparePage write FOnComparePage;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnParentColorChange: TNotifyEvent read FOnParentColorChanged write FOnParentColorChanged;
    property OnCustomDrawItem: TTVCustomDrawItemEvent read FOnCustomDrawItem write FOnCustomDrawItem;
    property OnEditCancelled: TNotifyEvent read FOnEditCancelled write FOnEditCancelled;
    property OnSelectionChange: TNotifyEvent read FOnSelectionChange write FOnSelectionChange;
  end;

implementation

uses
  JclSysUtils, JclStrings, JvJCLUtils, JvTypes;

const
  TVIS_CHECKED = $2000;

// === TJvIPAddressRange =====================================================

constructor TJvIPAddressRange.Create(Control: TWinControl);
var
  I: Integer;
begin
  inherited Create;
  FControl := Control;
  for I := Low(FRange) to High(FRange) do
  begin
    FRange[I].Min := 0;
    FRange[I].Max := 255;
  end;
end;

procedure TJvIPAddressRange.AssignTo(Dest: TPersistent);
begin
  if Dest is TJvIPAddressRange then
    with TJvIPAddressRange(Dest) do
    begin
      FRange := Self.FRange;
      Change(-1);
    end
  else
    inherited AssignTo(Dest);
end;

procedure TJvIPAddressRange.Change(Index: Integer);
var
  I: Integer;

  procedure ChangeRange(FieldIndex: Integer);
  begin
    with FRange[FieldIndex] do
      FControl.Perform(IPM_SETRANGE, FieldIndex, MAKEIPRANGE(Min, Max));
  end;

begin
  if not FControl.HandleAllocated then
    Exit;
  if Index = -1 then
    for I := Low(FRange) to High(FRange) do
      ChangeRange(I)
  else
    ChangeRange(Index);
end;

function TJvIPAddressRange.GetMaxRange(Index: Integer): Byte;
begin
  Result := FRange[Index].Max;
end;

function TJvIPAddressRange.GetMinRange(Index: Integer): Byte;
begin
  Result := FRange[Index].Min;
end;

procedure TJvIPAddressRange.SetMaxRange(const Index: Integer; const Value: Byte);
begin
  FRange[Index].Max := Value;
  Change(Index);
end;

procedure TJvIPAddressRange.SetMinRange(const Index: Integer; const Value: Byte);
begin
  FRange[Index].Min := Value;
  Change(Index);
end;

// === TJvIPEditControlHelper ==================================================

constructor TJvIPEditControlHelper.Create(AIPAddress: TJvIPAddress);
begin
  inherited Create;
  FHandle := 0;
  FIPAddress := AIPAddress;
  FInstance := MakeObjectInstance(WndProc);
end;

procedure TJvIPEditControlHelper.DefaultHandler(var Msg);
begin
  with TMessage(Msg) do
    Result := CallWindowProc(FOrgWndProc, FHandle, Msg, WParam, LParam);
end;

destructor TJvIPEditControlHelper.Destroy;
begin
  Handle := 0;
  if Assigned(FInstance) then
    FreeObjectInstance(FInstance);
  inherited Destroy;
end;

procedure TJvIPEditControlHelper.SetHandle(const Value: THandle);
begin
  if Value <> FHandle then
  begin
    if FHandle <> 0 then
      SetWindowLong(FHandle, GWL_WNDPROC, Integer(FOrgWndProc));

    FHandle := Value;

    if FHandle <> 0 then
    begin
      FOrgWndProc := Pointer(GetWindowLong(FHandle, GWL_WNDPROC));
      SetWindowLong(FHandle, GWL_WNDPROC, Integer(FInstance));
    end;
  end;
end;

procedure TJvIPEditControlHelper.WndProc(var Msg: TMessage);
begin
  case Msg.Msg of
    WM_DESTROY:
      Handle := 0;

    WM_KEYFIRST..WM_KEYLAST:
      FIPAddress.Dispatch(Msg);

    // mouse messages are sent through TJvIPAddress.WMParentNotify
  end;
  Dispatch(Msg);
end;

// === TJvIPAddress ==========================================================

constructor TJvIPAddress.Create(AOwner: TComponent);
var
  I: Integer;
begin
  CheckCommonControl(ICC_INTERNET_CLASSES);
  inherited Create(AOwner);
  FRange := TJvIPAddressRange.Create(Self);
  FAddressValues := TJvIPAddressValues.Create;
  FAddressValues.OnChange := DoAddressChange;
  FAddressValues.OnChanging := DoAddressChanging;

  ControlStyle := ControlStyle + [csFixedHeight, csReflector];
  Color := clWindow;
  ParentColor := False;
  TabStop := True;
  Width := 150;
  AdjustHeight;

  for I := 0 to High(FEditControls) do
    FEditControls[I] := TJvIPEditControlHelper.Create(Self);
end;

destructor TJvIPAddress.Destroy;
var
  I: Integer;
begin
  FreeAndNil(FRange);
  FreeAndNil(FAddressValues);
  inherited Destroy;
  // (ahuser) I don't know why but TWinControl.DestroyWindowHandle raises an AV
  //          when FEditControls are released before inherited Destroy.
  for I := 0 to High(FEditControls) do
    FEditControls[I].Free;
end;

procedure TJvIPAddress.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  CreateSubClass(Params, WC_IPADDRESS);
  with Params do
  begin
    Style := Style or WS_CHILD;
    WindowClass.style := WindowClass.style and not (CS_HREDRAW or CS_VREDRAW);
  end;
end;

procedure TJvIPAddress.CreateWnd;
begin
  ClearEditControls;
  FChanging := True;
  try
    inherited CreateWnd;
    FRange.Change(-1);
    if FSaveBlank then
      ClearAddress
    else
    begin
      Perform(IPM_SETADDRESS, 0, FAddress);
      FAddressValues.Address := FAddress;
    end;
  finally
    FChanging := False;
  end;
end;

procedure TJvIPAddress.DestroyLocalFont;
begin
  if LocalFont <> 0 then
  begin
    OSCheck(DeleteObject(LocalFont));
    LocalFont := 0;
  end;
end;

procedure TJvIPAddress.DestroyWnd;
begin
  FSaveBlank := IsBlank;
  inherited DestroyWnd;
end;

procedure TJvIPAddress.AdjustHeight;
var
  DC: HDC;
  SaveFont: HFont;
  //  I: Integer;
  //  R: TRect;
  Metrics: TTextMetric;
begin
  DC := GetDC(0);
  SaveFont := SelectObject(DC, Font.Handle);
  GetTextMetrics(DC, Metrics);
  SelectObject(DC, SaveFont);
  ReleaseDC(0, DC);
  Height := Metrics.tmHeight + (GetSystemMetrics(SM_CYBORDER) * 8);
  {  for I := 0 to FEditControlCount - 1 do
    begin
      GetWindowRect(FEditControls[I], R);
      R.TopLeft := ScreenToClient(R.TopLeft);
      R.BottomRight := ScreenToClient(R.BottomRight);
      OffsetRect(R, -R.Left, -R.Top);
      R.Bottom := ClientHeight;
      SetWindowPos(FEditControls[I], 0, 0, 0, R.Right, R.Bottom,
        SWP_NOMOVE or SWP_NOZORDER or SWP_NOACTIVATE);
    end;}
end;

procedure TJvIPAddress.AdjustSize;
begin
  inherited AdjustSize;
  RecreateWnd;
end;

procedure TJvIPAddress.ClearAddress;
begin
  if HandleAllocated then
    Perform(IPM_CLEARADDRESS, 0, 0);
  FAddressValues.Address := 0;
end;

procedure TJvIPAddress.ClearEditControls;
var
  I: Integer;
begin
  for I := 0 to High(FEditControls) do
    if FEditControls[I] <> nil then
      FEditControls[I].Handle := 0;
  FEditControlCount := 0;
end;

procedure TJvIPAddress.ColorChanged;
begin
  inherited ColorChanged;
  Invalidate;
end;

procedure TJvIPAddress.FontChanged;
begin
  inherited FontChanged;
  AdjustHeight;
  Invalidate;
end;

procedure TJvIPAddress.EnabledChanged;
var
  I: Integer;
begin
  inherited EnabledChanged;
  for i := 0 to High(FEditControls) do
    if (FEditControls[I] <> nil) and (FEditControls[I].Handle <> 0) then
      EnableWindow(FEditControls[I].Handle,
        Enabled and not (csDesigning in ComponentState));
end;

procedure TJvIPAddress.CNCommand(var Msg: TWMCommand);
begin
  with Msg do
    case NotifyCode of
      EN_CHANGE:
        begin
          Perform(IPM_GETADDRESS, 0, Integer(@FAddress));
          if not FChanging then
            DoChange;
        end;
      EN_KILLFOCUS:
        begin
          FChanging := True;
          try
            if not IsBlank then
              Perform(IPM_SETADDRESS, 0, FAddress);
          finally
            FChanging := False;
          end;
        end;
    end;
  inherited;
end;

procedure TJvIPAddress.CNNotify(var Msg: TWMNotify);
begin
  with Msg, NMHdr^ do
    if code = IPN_FIELDCHANGED then
      with PNMIPAddress(NMHdr)^ do
        DoFieldChange(iField, iValue);
  inherited;
end;

procedure TJvIPAddress.DoAddressChange(Sender: TObject);
begin
  Address := FAddressValues.Address;
end;

procedure TJvIPAddress.DoAddressChanging(Sender: TObject; Index: Integer; Value: Byte; var AllowChange: Boolean);
begin
  AllowChange := (Index > -1) and (Index < 4) and
    (Value >= FRange.FRange[Index].Min) and (Value <= FRange.FRange[Index].Max);
end;

procedure TJvIPAddress.DoChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TJvIPAddress.DoFieldChange(FieldIndex: Integer; var FieldValue: Integer);
begin
  if Assigned(FOnFieldChange) then
    FOnFieldChange(Self, FieldIndex, FRange.FRange[FieldIndex], FieldValue);
end;

function TJvIPAddress.IsBlank: Boolean;
begin
  Result := False;
  if HandleAllocated then
    Result := SendMessage(Handle, IPM_ISBLANK, 0, 0) <> 0;
end;

procedure TJvIPAddress.SetAddress(const Value: LongWord);
begin
  if FAddress <> Value then
  begin
    FAddress := Value;
    if HandleAllocated then
      Perform(IPM_SETADDRESS, 0, FAddress);
    FAddressValues.Address := Value;
  end;
end;

procedure TJvIPAddress.SetAddressValues(const Value: TJvIPAddressValues);
begin
  //  (p3) do nothing
end;

procedure TJvIPAddress.WMDestroy(var Msg: TWMNCDestroy);
begin
  DestroyLocalFont;
  inherited;
end;

function TJvIPAddress.DoPaintBackground(Canvas: TCanvas; Param: Integer): Boolean;
begin
  Result := True;
end;

procedure TJvIPAddress.DoGetDlgCode(var Code: TDlgCodes);
begin
  Include(Code, dcWantArrows);
  Exclude(Code, dcNative); // prevent inherited call
end;

procedure TJvIPAddress.TextChanged;
var S:string;
begin
  inherited;
  S := Text;
  with AddressValues do
  begin
    Value1 := StrToIntDef(StrToken(S, '.'), 0);
    Value2 := StrToIntDef(StrToken(S, '.'), 0);
    Value3 := StrToIntDef(StrToken(S, '.'), 0);
    Value4 := StrToIntDef(S, 0);
  end;
end;

procedure TJvIPAddress.WMParentNotify(var Msg: TWMParentNotify);
begin
  with Msg do
    case Event of
      WM_CREATE:
        begin
          if (FEditControlCount <= Length(FEditControls)) and
             (FEditControls[FEditControlCount] <> nil) then
          begin
            FEditControls[FEditControlCount].Handle := ChildWnd;
            EnableWindow(ChildWnd, Enabled and not (csDesigning in ComponentState));
            Inc(FEditControlCount);
          end;
        end;
      WM_DESTROY:
        ClearEditControls;
      WM_LBUTTONDOWN, WM_MBUTTONDOWN, WM_RBUTTONDOWN:
        Perform(Event, Value, Integer(SmallPoint(XPos, YPos)));
    end;
  inherited;
end;

procedure TJvIPAddress.WMSetFont(var Msg: TWMSetFont);
var                   
  LF: TLogFont;
begin
  FillChar(LF, SizeOf(TLogFont), #0);
  try
    OSCheck(GetObject(Font.Handle, SizeOf(LF), @LF) > 0);
    DestroyLocalFont;
    LocalFont := CreateFontIndirect(LF);
    Msg.Font := LocalFont;
    inherited;
  except
    Application.HandleException(Self);
  end;
end;

// === TJvPageControl ========================================================

constructor TJvPageControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FColor := clInfoBk;
  FClientBorderWidth := JvDefPageControlBorder;
  FHintSource := hsDefault;
end;

function TJvPageControl.FormKeyPreview: Boolean;
var
  F: TCustomForm;
begin
  F := GetParentForm(Self);
  if F <> nil then
    Result := F.KeyPreview
  else
    Result := False;
end;

function TJvPageControl.WantKey(Key: Integer; Shift: TShiftState;
  const KeyText: WideString): Boolean;
var
  thistab, tab: TTabSheet;
  forwrd: Boolean;
begin
  Result := False;
  if HandleGlobalTab and not FormKeyPreview and (Key = VK_TAB) and (GetKeyState(VK_CONTROL) < 0) then
  begin
    thistab := ActivePage;
    forwrd := GetKeyState(VK_SHIFT) >= 0;
    tab := thistab;
    repeat
      tab := FindNextPage(tab, forwrd, True);
    until (tab = nil) or tab.Enabled or (tab = thistab);
    if tab <> thistab then
    begin
      if CanChange then
      begin
        ActivePage := tab;
        Result := True;
        Change;
      end;
      Exit;
    end;
  end;
  Result := inherited WantKey(Key, Shift, KeyText);
end;

procedure TJvPageControl.ParentColorChanged;
begin
  inherited ParentColorChanged;
  if Assigned(FOnParentColorChanged) then
    FOnParentColorChanged(Self);
end;

procedure TJvPageControl.DrawDefaultTab(TabIndex: Integer;
  const Rect: TRect; Active: Boolean; DefaultDraw: Boolean);
var
  ImageIndex, RealIndex: Integer;
  R: TRect;
  S: string;
begin
  RealIndex := TabIndex;
  while not Pages[RealIndex].TabVisible do
    Inc(RealIndex);
  if RealIndex >= PageCount then Exit;

  if not Pages[RealIndex].Enabled then
    Canvas.Font.Color := clGrayText;
  if Active then
    Canvas.Font.Style := [fsBold];
  if not DefaultDraw then
    Exit;
  R := Rect;
  Canvas.FillRect(R);
  ImageIndex := GetImageIndex(TabIndex);
  if (ImageIndex >= 0) and Assigned(Images) then
  begin
    SaveDC(Canvas.Handle);
    Images.Draw(Canvas, Rect.Left + 4, Rect.Top + 2,
      ImageIndex, Pages[RealIndex].Enabled);
    // images.draw fouls the canvas colors if it draws
    // the image disabled, thus the SaveDC/RestoreDC
    RestoreDC(Canvas.Handle, -1);
    R.Left := R.Left + Images.Width + 4;
  end;
  S := Pages[RealIndex].Caption;
  InflateRect(R, -2, -2);
  // (p3) TODO: draw rotated when TabPosition in tbLeft, tbRight
  DrawText(Canvas.Handle, PChar(S), Length(S), R, DT_SINGLELINE or DT_LEFT or DT_TOP);
end;

procedure TJvPageControl.DrawShadowTab(TabIndex: Integer;
  const Rect: TRect; Active: Boolean; DefaultDraw: Boolean);
var
  ImageIndex, RealIndex: Integer;
  R: TRect;
  S: string;
begin
  //inherited;
  RealIndex := TabIndex;
  while not Pages[RealIndex].TabVisible do
    Inc(RealIndex);
  if RealIndex >= PageCount then Exit;

  if not Pages[RealIndex].Enabled then
    Canvas.Font.Color := clGrayText;
  if not Active then
  begin
    with Canvas do
    begin
      Brush.Color := clInactiveCaption;
      Font.Color := clInactiveCaptionText;
    end;
  end;
  if not DefaultDraw then
    Exit;
  R := Rect;
  Canvas.FillRect(R);
  ImageIndex := GetImageIndex(TabIndex);
  if (ImageIndex >= 0) and Assigned(Images) then
  begin
    SaveDC(Canvas.Handle);
    Images.Draw(Canvas, Rect.Left + 4, Rect.Top + 2,
      ImageIndex, Pages[RealIndex].Enabled);
    RestoreDC(Canvas.Handle, -1);
    R.Left := R.Left + Images.Width + 4;
  end;
  S := Pages[RealIndex].Caption;
  InflateRect(R, -2, -2);
  DrawText(Canvas.Handle, PChar(S), Length(S), R, DT_SINGLELINE or DT_LEFT or DT_TOP);
end;

procedure TJvPageControl.DrawTab(TabIndex: Integer; const Rect: TRect;
  Active: Boolean);
begin
  if DrawTabShadow then
    DrawShadowTab(TabIndex, Rect, Active, Assigned(OnDrawTab))
  else
    DrawDefaultTab(TabIndex, Rect, Active, Assigned(OnDrawTab));
end;

procedure TJvPageControl.Loaded;
begin
  inherited Loaded;
  HideAllTabs := FHideAllTabs;
end;

procedure TJvPageControl.MouseEnter(Control: TControl);
begin
  if csDesigning in ComponentState then
    Exit;
  FSaved := Application.HintColor;
  Application.HintColor := FColor;
  inherited MouseEnter(Control);
end;

procedure TJvPageControl.MouseLeave(Control: TControl);
begin
  if csDesigning in ComponentState then
    Exit;
  Application.HintColor := FSaved;
  inherited MouseLeave(Control);
end;

procedure TJvPageControl.SetClientBorderWidth(const Value: TBorderWidth);
begin
  if FClientBorderWidth <> Value then
  begin
    FClientBorderWidth := Value;
    RecreateWnd;
  end;
end;

procedure TJvPageControl.SetDrawTabShadow(const Value: Boolean);
begin
  if FDrawTabShadow <> Value then
  begin
    FDrawTabShadow := Value;
    Invalidate;
  end;
end;

procedure TJvPageControl.SetHideAllTabs(const Value: Boolean);
var
  I: Integer;
  SaveActivePage: TTabSheet;
begin
  FHideAllTabs := Value;
  if (csDesigning in ComponentState) then
    Exit;
  if HandleAllocated then
  begin
    SaveActivePage := ActivePage;
    for I := 0 to PageCount - 1 do
      Pages[I].TabVisible := Pages[I].TabVisible and not FHideAllTabs;
    ActivePage := SaveActivePage;
    if FHideAllTabs then
      TabStop := False;
  end;
end;

procedure TJvPageControl.TCMAdjustRect(var Msg: TMessage);
var
  Offset: Integer;
begin
  inherited;
  if (Msg.WParam = 0) and (FClientBorderWidth <> JvDefPageControlBorder) then
  begin
    Offset := JvDefPageControlBorder - FClientBorderWidth;
    InflateRect(PRect(Msg.LParam)^, Offset, Offset);
  end;
end;

procedure TJvPageControl.UpdateTabImages;
begin
  inherited UpdateTabImages;
end;

procedure TJvPageControl.WMLButtonDown(var Msg: TWMLButtonDown);
var
  hi: TTCHitTestInfo;
  TabIndex: Integer;
begin
  if csDesigning in ComponentState then
  begin
    inherited;
    Exit;
  end;
  hi.pt.x := Msg.XPos;
  hi.pt.y := Msg.YPos;
  hi.flags := 0;
  TabIndex := Perform(TCM_HITTEST, 0, Longint(@hi));
  if (TabIndex >= 0) and ((hi.flags and TCHT_ONITEM) <> 0) then
    if not Pages[TabIndex].Enabled then
    begin
      Msg.Result := 0;
      Exit;
    end;
  inherited;
end;

// === TJvTrackBar ===========================================================

constructor TJvTrackBar.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FColor := clInfoBk;
  // ControlStyle := ControlStyle + [csAcceptsControls];
  FToolTipSide := tsLeft;
  FShowRange := True;
end;

procedure TJvTrackBar.ParentColorChanged;
begin
  inherited ParentColorChanged;
  if Assigned(FOnParentColorChanged) then
    FOnParentColorChanged(Self);
end;

procedure TJvTrackBar.CNHScroll(var Msg: TWMHScroll);
begin
  if Msg.ScrollCode <> SB_ENDSCROLL then
    inherited;
end;

procedure TJvTrackBar.CNVScroll(var Msg: TWMVScroll);
begin
  if Msg.ScrollCode <> SB_ENDSCROLL then
    inherited;
end;

procedure TJvTrackBar.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  with Params do
  begin
    if FToolTips and (GetComCtlVersion >= ComCtlVersionIE3) then
      Style := Style or TBS_TOOLTIPS;
    // (p3) this stolen from Rudy Velthuis's ExTrackBar
    if not ShowRange then
      Style := Style and not TBS_ENABLESELRANGE;
  end;
end;

procedure TJvTrackBar.CreateWnd;
begin
  inherited CreateWnd;
  InternalSetToolTipSide;
end;

procedure TJvTrackBar.InternalSetToolTipSide;
const
  ToolTipSides: array [TJvTrackToolTipSide] of DWORD =
    (TBTS_LEFT, TBTS_TOP, TBTS_RIGHT, TBTS_BOTTOM);
begin
  if HandleAllocated and (GetComCtlVersion >= ComCtlVersionIE3) then
    SendMessage(Handle, TBM_SETTIPSIDE, ToolTipSides[FToolTipSide], 0);
end;

procedure TJvTrackBar.MouseEnter(Control: TControl);
begin
  if csDesigning in ComponentState then
    Exit;
  FSaved := Application.HintColor;
  Application.HintColor := FColor;
  inherited MouseEnter(Control);
end;

procedure TJvTrackBar.MouseLeave(Control: TControl);
begin
  if csDesigning in ComponentState then
    Exit;
  Application.HintColor := FSaved;
  inherited MouseLeave(Control);
end;

procedure TJvTrackBar.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  if Assigned(FOnChanged) then
    FOnChanged(Self);
end;

procedure TJvTrackBar.SetShowRange(const Value: Boolean);
begin
  if FShowRange <> Value then
  begin
    FShowRange := Value;
    RecreateWnd;
  end;
end;

procedure TJvTrackBar.SetToolTips(const Value: Boolean);
begin
  if FToolTips <> Value then
  begin
    FToolTips := Value;
    RecreateWnd;
  end;
end;

procedure TJvTrackBar.SetToolTipSide(const Value: TJvTrackToolTipSide);
begin
  if FToolTipSide <> Value then
  begin
    FToolTipSide := Value;
    InternalSetToolTipSide;
  end;
end;

procedure TJvTrackBar.WMNotify(var Msg: TWMNotify);
var
  ToolTipTextLocal: string;
begin
  with Msg do
    if (NMHdr^.code = TTN_NEEDTEXTW) and Assigned(FOnToolTip) then
      with PNMTTDispInfoW(NMHdr)^ do
      begin
        hinst := 0;
        ToolTipTextLocal := IntToStr(Position);
        FOnToolTip(Self, ToolTipTextLocal);
        FToolTipText := ToolTipTextLocal;
        lpszText := PWideChar(FToolTipText);
        FillChar(szText, SizeOf(szText), #0);
        Result := 1;
      end
    else
      inherited;
end;

// === TJvTreeNode ===========================================================

class function TJvTreeNode.CreateEnh(AOwner: TTreeNodes): TJvTreeNode;
begin
  Result := Create(AOwner);
  Result.FPopupMenu := TPopupMenu.Create(AOwner.Owner);
end;

procedure TJvTreeNode.SetPopupMenu(const Value: TPopupMenu);
begin
  FPopupMenu := Value;
end;

function TJvTreeNode.GetBold: Boolean;
var
  Item: TTVItem;
begin
  with Item do
  begin
    mask := TVIF_STATE;
    hItem := ItemId;
    if TreeView_GetItem(Handle, Item) then
      Result := ((Item.State and TVIS_BOLD) = TVIS_BOLD)
    else
      Result := False;
  end;
end;

function TJvTreeNode.GetChecked: Boolean;
var
  Item: TTVItem;
begin
  with Item do
  begin
    mask := TVIF_STATE;
    hItem := ItemId;
    if TreeView_GetItem(Handle, Item) then
      Result := ((Item.State and TVIS_CHECKED) = TVIS_CHECKED)
    else
      Result := False;
  end;
end;

procedure TJvTreeNode.SetBold(const Value: Boolean);
var
  Item: TTVItem;
begin
  FBold := Value;
  FillChar(Item, SizeOf(Item), 0);
  with Item do
  begin
    mask := TVIF_STATE;
    hItem := ItemId;
    StateMask := TVIS_BOLD;
    if FBold then
      Item.State := TVIS_BOLD
    else
      Item.State := 0;
    TreeView_SetItem(Handle, Item);
  end;
end;

procedure TJvTreeNode.SetChecked(Value: Boolean);
var
  Item: TTVItem;
begin
  FChecked := Value;
  FillChar(Item, SizeOf(Item), 0);
  with Item do
  begin
    hItem := ItemId;
    mask := TVIF_STATE;
    StateMask := TVIS_STATEIMAGEMASK;
    if FChecked then
      Item.State := TVIS_CHECKED
    else
      Item.State := TVIS_CHECKED shr 1;
    TreeView_SetItem(Handle, Item);
  end;
end;

// === TJvTreeView ===========================================================

const
  AutoScrollMargin = 20;
  AutoScrollTimerID = 100;

constructor TJvTreeView.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FColor := clInfoBk;
  FOver := False;
  FCheckBoxes := False;
  // ControlStyle := ControlStyle + [csAcceptsControls];
  FSelectedList := TObjectList.Create(False);
  // Since IsCustomDrawn method is not virtual we have to assign ancestor's
  // OnCustomDrawItem event to enable custom drawing
  if not (csDesigning in ComponentState) then
    inherited OnCustomDrawItem := InternalCustomDrawItem;
end;

destructor TJvTreeView.Destroy;
begin
  FreeAndNil(FSelectedList);
  inherited Destroy;
end;

procedure TJvTreeView.Change(Node: TTreeNode);
begin
  if FClearBeforeSelect then
  begin
    FClearBeforeSelect := False;
    ClearSelection;
  end;
  if FSelectThisNode then
  begin
    FSelectThisNode := False;
    SelectItem(Node);
  end;
  inherited Change(Node);
end;

procedure TJvTreeView.ClearSelection;
var
  NeedInvalidate: array of TTreeNode;
  I: Integer;
begin
  FClearBeforeSelect := False;
  if FSelectedList.Count = 0 then
    Exit;
  DoSelectionChange;
  SetLength(NeedInvalidate, FSelectedList.Count);
  for I := 0 to FSelectedList.Count - 1 do
    NeedInvalidate[I] := SelectedItems[I];
  FSelectedList.Clear;
  for I := 0 to Length(NeedInvalidate) - 1 do
    InvalidateNode(NeedInvalidate[I]);
end;

procedure TJvTreeView.ParentColorChanged;
begin
  inherited ParentColorChanged;
  if Assigned(FOnParentColorChanged) then
    FOnParentColorChanged(Self);
end;

function TJvTreeView.CreateNode: TTreeNode;
begin
  Result := TJvTreeNode.CreateEnh(Items);
end;

procedure TJvTreeView.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  if FCheckBoxes then
    Params.Style := Params.Style or TVS_CHECKBOXES;
end;

procedure TJvTreeView.Delete(Node: TTreeNode);
begin
  if FMultiSelect then
    FSelectedList.Remove(Node);
  inherited Delete(Node);
end;

procedure TJvTreeView.DoEditCancelled;
begin
  if Assigned(FOnEditCancelled) then
    FOnEditCancelled(Self);
end;

procedure TJvTreeView.DoEndDrag(Target: TObject; X, Y: Integer);
begin
  ScrollDirection := 0;
  inherited DoEndDrag(Target, X, Y);
end;

procedure TJvTreeView.DoEnter;
begin
  InvalidateSelectedItems;
  inherited DoEnter;
end;

procedure TJvTreeView.DoExit;
begin
  InvalidateSelectedItems;
  inherited DoExit;
end;

procedure TJvTreeView.DoSelectionChange;
begin
  if Assigned(FOnSelectionChange) then
    FOnSelectionChange(Self);
end;

procedure TJvTreeView.DragOver(Source: TObject; X, Y: Integer;
  State: TDragState; var Accept: Boolean);
begin
  inherited DragOver(Source, X, Y, State, Accept);
  if not FAutoDragScroll then
    Exit;
  if Y < AutoScrollMargin then
    ScrollDirection := -1
  else
  if Y > ClientHeight - AutoScrollMargin then
    ScrollDirection := 1
  else
    ScrollDirection := 0;
end;

procedure TJvTreeView.Edit(const Item: TTVItem);
begin
  inherited Edit(Item);
  if Item.pszText = nil then
    DoEditCancelled;
end;

function TJvTreeView.GetBold(Node: TTreeNode): Boolean;
begin
  Result := TJvTreeNode(Node).Bold;
end;

function TJvTreeView.GetChecked(Node: TTreenode): Boolean;
begin
  Result := TJvTreeNode(Node).Checked;
end;

function TJvTreeView.GetNodePopup(Node: TTreeNode): TPopupMenu;
begin
  Result := TJvTreeNode(Node).PopupMenu;
end;

function TJvTreeView.GetSelectedCount: Integer;
begin
  if FMultiSelect then
    Result := FSelectedList.Count
  else
    Result := -1;
end;

function TJvTreeView.GetSelectedItem(Index: Integer): TTreeNode;
begin
  Result := TTreeNode(FSelectedList[Index]);
end;

procedure TJvTreeView.InternalCustomDrawItem(Sender: TCustomTreeView;
  Node: TTreeNode; State: TCustomDrawState; var DefaultDraw: Boolean);
begin
  if FMultiSelect then
  begin
    with Canvas.Font do
    begin // fix HotTrack bug in custom drawing
      OnChange(nil);
      if cdsHot in State then
      begin
        Style := Style + [fsUnderLine];
        if cdsSelected in State then
          Color := clHighlightText
        else
          Color := clHighlight;
      end;
    end;
    if IsNodeSelected(Node) then
    begin
      if Focused then
      begin
        Canvas.Font.Color := clHighlightText;
        Canvas.Brush.Color := clHighlight;
      end
      else
      if not HideSelection then
      begin
        Canvas.Font.Color := Font.Color;
        Canvas.Brush.Color := clInactiveBorder;
      end;
    end
    else
    begin
      Canvas.Font.Color := Font.Color;
      Canvas.Brush.Color := Color;
    end;
  end;
  if Assigned(FOnCustomDrawItem) then
    FOnCustomDrawItem(Self, Node, State, DefaultDraw);
end;

procedure TJvTreeView.InvalidateNode(Node: TTreeNode);
var
  R: TRect;
begin
  if Assigned(Node) and Node.IsVisible then
  begin
    R := Node.DisplayRect(True);
    InvalidateRect(Handle, @R, False);
  end;
end;

procedure TJvTreeView.InvalidateNodeIcon(Node: TTreeNode);
var
  R: TRect;
begin
  if Assigned(Node) and Assigned(Images) and Node.IsVisible then
  begin
    R := Node.DisplayRect(True);
    R.Right := R.Left;
    R.Left := R.Left - Images.Width * 3;
    InvalidateRect(Handle, @R, True);
  end;
end;

procedure TJvTreeView.InvalidateSelectedItems;
var
  I: Integer;
begin
  if HandleAllocated then
    for I := 0 to SelectedCount - 1 do
      InvalidateNode(SelectedItems[I]);
end;

function TJvTreeView.IsNodeSelected(Node: TTreeNode): Boolean;
begin
  Result := FSelectedList.IndexOf(Node) <> -1;
end;

procedure TJvTreeView.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if FMultiSelect then
  begin
    ResetPostOperationFlags;
    if not (ssAlt in Shift) then
    begin
      if Key = VK_SPACE then
        SelectItem(Selected, IsNodeSelected(Selected))
      else
      begin
        FSelectThisNode := True;
        if Shift * [ssShift, ssCtrl] = [] then
          FClearBeforeSelect := True;
      end;
    end;
  end;
  inherited KeyDown(Key, Shift);
end;

procedure TJvTreeView.KeyPress(var Key: Char);
begin
  if FMultiSelect and (Key = ' ') then
    Key := #0
  else
    inherited KeyPress(Key);
end;

procedure TJvTreeView.MouseEnter(Control: TControl);
begin
  if csDesigning in ComponentState then
    Exit;
  if not FOver then
  begin
    FOver := True;
    FSaved := Application.HintColor;
    Application.HintColor := FColor;
    inherited MouseEnter(Control);
  end;
end;

procedure TJvTreeView.MouseLeave(Control: TControl);
begin
  if FOver then
  begin
    FOver := False;
    Application.HintColor := FSaved;
    inherited MouseLeave(Control);
  end;
end;

procedure TJvTreeView.ResetPostOperationFlags;
begin
  FClearBeforeSelect := False;
  FSelectThisNode := False;
end;

procedure TJvTreeView.SelectItem(Node: TTreeNode; Unselect: Boolean);
begin
  if Unselect then
    FSelectedList.Remove(Node)
  else
  if not IsNodeSelected(Node) then
    FSelectedList.Add(Node);
  if HandleAllocated then
    InvalidateNode(Node);
  DoSelectionChange;
end;

procedure TJvTreeView.SetBold(Node: TTreeNode; Value: Boolean);
begin
  TJvTreeNode(Node).Bold := Value;
end;

procedure TJvTreeView.SetCheckBoxes(const Value: Boolean);
begin
  FCheckBoxes := Value;
  RecreateWnd;
end;

procedure TJvTreeView.SetChecked(Node: TTreenode; Value: Boolean);
begin
  TJvTreeNode(Node).Checked := Value;
end;

{$IFNDEF COMPILER6_UP}
procedure TJvTreeView.SetMultiSelect(const Value: Boolean);
begin
  if FMultiSelect <> Value then
  begin
    FMultiSelect := Value;
    ResetPostOperationFlags;
    ClearSelection;
  end;
end;
{$ENDIF COMPILER6_UP}

procedure TJvTreeView.SetNodePopup(Node: TTreeNode; Value: TPopupMenu);
begin
  TJvTreeNode(Node).PopupMenu := Value;
end;

procedure TJvTreeView.SetScrollDirection(const Value: Integer);
begin
  if FScrollDirection <> Value then
  begin
    if Value = 0 then
      KillTimer(Handle, AutoScrollTimerID)
    else
    if (Value <> 0) and (FScrollDirection = 0) then
      SetTimer(Handle, AutoScrollTimerID, 200, nil);
    FScrollDirection := Value;
  end;
end;

procedure TJvTreeView.WMHScroll(var Msg: TWMHScroll);
begin
  inherited;
  if Assigned(FOnHScroll) then
    FOnHScroll(Self);
end;

procedure TJvTreeView.WMLButtonDown(var Msg: TWMLButtonDown);
var
  Node: TTreeNode;
begin
  ResetPostOperationFlags;
  with Msg do
    if FMultiSelect and (htOnItem in GetHitTestInfoAt(XPos, YPos)) then
    begin
      Node := GetNodeAt(XPos, YPos);
      if Assigned(Node) and (ssCtrl in KeysToShiftState(Keys)) then
        SelectItem(Node, IsNodeSelected(Node))
      else
      begin
        ClearSelection;
        SelectItem(Node);
      end;
    end;
  inherited;
end;

procedure TJvTreeView.WMNotify(var Msg: TWMNotify);
var
  Node: TTreeNode;
  Point: TPoint;
  I, J: Integer;
begin
  inherited;

  if not Windows.GetCursorPos(Point) then
    Exit;
  Point := ScreenToClient(Point);
  with Msg, Point do
    case NMHdr^.code of
      NM_CLICK, NM_RCLICK:
        begin
          Node := GetNodeAt(x, y);
          if Assigned(Node) then
            Selected := Node
          else
          begin
            if FCheckBoxes then
            begin
              Node := GetNodeAt(x + 16, y);
              if Assigned(Node) then
                Selected := Node
            end;
          end;
          if (Selected <> nil) and (NMHdr^.code = NM_RCLICK) then
            TJvTreeNode(Selected).PopupMenu.Popup(Mouse.CursorPos.x, Mouse.CursorPos.y);
        end;
      TVN_SELCHANGEDA, TVN_SELCHANGEDW:
        begin
          if Assigned(FPageControl) then
            if Selected <> nil then
            begin
              //Search for the correct page
              J := -1;
              for I := 0 to FPageControl.PageCount - 1 do
                if DoComparePage(FPageControl.Pages[I], Selected) then
                  J := I;
              if J <> -1 then
              begin
                FPageControl.ActivePage := FPageControl.Pages[J];
                if Assigned(FOnPage) then
                  FOnPage(Self, Selected, FPageControl.Pages[J]);
              end;
            end;
        end;

    end;
end;

function TJvTreeView.DoComparePage(Page: TTabSheet; Node: TTreeNode): Boolean;
begin
  if Assigned(FOnComparePage) then
    FOnComparePage(Self, Page, Node, Result)
  else
    Result := AnsiCompareText(Page.Caption, Node.Text) = 0;
end;

procedure TJvTreeView.WMTimer(var Msg: TWMTimer);
var
  DragImages: TDragImageList;
begin
  if Msg.TimerID = AutoScrollTimerID then
  begin
    DragImages := GetDragImages;
    if Assigned(DragImages) then
      DragImages.HideDragImage;
    case FScrollDirection of
      -1:
        SendMessage(Handle, WM_VSCROLL, SB_LINEUP, 0);
      1:
        SendMessage(Handle, WM_VSCROLL, SB_LINEDOWN, 0);
    end;
    if Assigned(DragImages) then
      DragImages.ShowDragImage;
    Msg.Result := 1;
  end
  else
    inherited;
end;

procedure TJvTreeView.WMVScroll(var Msg: TWMVScroll);
begin
  inherited;
  if Assigned(FOnVScroll) then
    FOnVScroll(Self);
end;

// === TJvIPAddressValues ====================================================

procedure TJvIPAddressValues.Change;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

function TJvIPAddressValues.Changing(Index: Integer; Value: Byte): Boolean;
begin
  Result := True;
  if Assigned(FOnChanging) then
    FOnChanging(Self, Index, Value, Result);
end;

function TJvIPAddressValues.GetValue: Cardinal;
begin
  Result := MAKEIPADDRESS(FValues[0], FValues[1], FValues[2], FValues[3]);
end;

function TJvIPAddressValues.GetValues(Index: Integer): Byte;
begin
  Result := FValues[Index];
end;

procedure TJvIPAddressValues.SetValue(const AValue: Cardinal);
var
  FChange: Boolean;
begin
  FChange := False;
  if GetValue <> AValue then
  begin
    if Changing(0, FIRST_IPADDRESS(AValue)) then
    begin
      FValues[0] := FIRST_IPADDRESS(AValue);
      FChange := True;
    end;
    if Changing(1, SECOND_IPADDRESS(AValue)) then
    begin
      FValues[1] := SECOND_IPADDRESS(AValue);
      FChange := True;
    end;
    if Changing(2, THIRD_IPADDRESS(AValue)) then
    begin
      FValues[2] := THIRD_IPADDRESS(AValue);
      FChange := True;
    end;
    if Changing(3, FOURTH_IPADDRESS(AValue)) then
    begin
      FValues[3] := FOURTH_IPADDRESS(AValue);
      FChange := True;
    end;
    if FChange then
      Change;
  end;
end;

procedure TJvIPAddressValues.SetValues(Index: Integer; Value: Byte);
begin
  if (Index >= Low(FValues)) and (Index <= High(FValues)) and (FValues[Index] <> Value) then
  begin
    FValues[Index] := Value;
    Change;
  end;
end;

function TJvTreeView.GetItemHeight: Integer;
begin
  if HandleAllocated then
    Result := SendMessage(Handle, TVM_GETITEMHEIGHT, 0, 0)
  else
    Result := 16;
end;

procedure TJvTreeView.SetItemHeight(Value: Integer);
begin
  if Value <= 0 then
    Value := 16;
  if HandleAllocated then
    SendMessage(Handle, TVM_SETITEMHEIGHT, Value, 0);
end;

function TJvTreeView.GetInsertMarkColor: TColor;
begin
  if HandleAllocated then
    Result := SendMessage(Handle, TVM_GETINSERTMARKCOLOR, 0, 0)
  else
    Result := clDefault;
end;

procedure TJvTreeView.SetInsertMarkColor(Value: TColor);
begin
  if HandleAllocated then
  begin
    if Value = clDefault then
      Value := Font.Color;
    SendMessage(Handle, TVM_SETINSERTMARKCOLOR, 0, ColorToRGB(Value));
  end;
end;

procedure TJvTreeView.InsertMark(Node: TTreeNode; MarkAfter: Boolean);
begin
  if HandleAllocated then
    if Node = nil then
      RemoveMark
    else
      SendMessage(Handle, TVM_SETINSERTMARK, Integer(MarkAfter), Integer(Node.ItemId));
end;

procedure TJvTreeView.RemoveMark;
begin
  if HandleAllocated then
    SendMessage(Handle, TVM_SETINSERTMARK, 0, 0);
end;

function TJvTreeView.GetLineColor: TColor;
begin
  if HandleAllocated then
    Result := SendMessage(Handle, TVM_GETLINECOLOR, 0, 0)
  else
    Result := clDefault;
end;

procedure TJvTreeView.SetLineColor(Value: TColor);
begin
  if HandleAllocated then
  begin
    if Value = clDefault then
      Value := Font.Color;
    SendMessage(Handle, TVM_SETLINECOLOR, 0, ColorToRGB(Value));
  end;
end;

function TJvTreeView.GetMaxScrollTime: Integer;
begin
  if HandleAllocated then
    Result := SendMessage(Handle, TVM_GETSCROLLTIME, 0, 0)
  else
    Result := -1;
end;

procedure TJvTreeView.SetMaxScrollTime(const Value: Integer);
begin
  if HandleAllocated then
    SendMessage(Handle, TVM_SETSCROLLTIME, Value, 0);
end;

function TJvTreeView.GetUseUnicode: Boolean;
begin
  if HandleAllocated then
    Result := Boolean(SendMessage(Handle, TVM_GETUNICODEFORMAT, 0, 0))
  else
    Result := False;
end;

procedure TJvTreeView.SetUseUnicode(const Value: Boolean);
begin
  // only try to change value if not running on NT platform
  // (see MSDN: CCM_SETUNICODEFORMAT explanation for details)
  if HandleAllocated and (Win32Platform <> VER_PLATFORM_WIN32_NT) then
    SendMessage(Handle, TVM_SETUNICODEFORMAT, Integer(Value), 0);
end;

function TJvPageControl.HintShow(var HintInfo: THintInfo): Boolean;
var
  TabNo: Integer;
  Tab: TTabsheet;
begin
  Result := inherited HintShow(HintInfo);

  if FHintSource = hsDefault then
    Exit;

  if Result then
    Exit;
(*
    hsDefault,    // use default hint behaviour (i.e as regular control)
    hsForceMain,  // use the main controls hint even if subitems have hints
    hsForceChildren, // always use subitems hints even if empty and main control has hint
    hsPreferMain, // use main control hint unless empty then use subitems hints
    hsPreferChildren // use subitems hints unless empty then use main control hint
    );
*)

  if Result or (Self <> HintInfo.HintControl) then
    Exit; // strange, hint requested by other component. Why should we deal with it?
  with HintInfo.CursorPos do
    TabNo := IndexOfTabAt(X, Y); // X&Y are expected in Client coordinates

  if (TabNo >= 0) and (TabNo < PageCount) then
    Tab := Pages[TabNo]
  else
    Tab := nil;
  if (FHintSource = hsForceMain) or ((FHintSource = hsPreferMain) and (GetShortHint(Hint) <> '')) then
    HintInfo.HintStr := GetShortHint(Hint)
  else
  if (Tab <> nil) and ((FHintSource = hsForceChildren) or ((FHintSource = hsPreferChildren) and
    (GetShortHint(Tab.Hint) <> ''))) then
    HintInfo.HintStr := GetShortHint(Tab.Hint)
end;

type
  THackTabSheet = class(TTabSheet);

function TJvPageControl.CanChange: Boolean;
begin
  Result := inherited CanChange;
  if Result and (ActivePage <> nil) and ReduceMemoryUse then
    THackTabSheet(ActivePage).DestroyHandle;
end;

procedure TJvPageControl.SetReduceMemoryUse(const Value: Boolean);
begin
  FReduceMemoryUse := Value;
end;



end.

