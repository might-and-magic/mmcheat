------------------------------------------------------------------------
--  Binding for IUP v3.12.0
--  MIT License
--  Originally from https://github.com/Playermet/luajit-iup by Playermet
--  Modified by Tom Chen (tomchen.org)
------------------------------------------------------------------------
local ffi = require 'ffi'

local const = {}

const._NAME = 'IUP - Portable User Interface'
const._COPYRIGHT = 'Copyright (C) 1994-2014 Tecgraf, PUC-Rio.'
const._DESCRIPTION = 'Multi-platform toolkit for building graphical user interfaces.'
const._VERSION = '3.12'
const._VERSION_NUMBER = 312000
const._VERSION_DATE = '2014/11/19'

const.ERROR = 1
const.NOERROR = 0
const.OPENED = -1
const.INVALID = -1
const.INVALID_ID = -10

const.IGNORE = -1
const.DEFAULT = -2
const.CLOSE = -3
const.CONTINUE = -4

const.CENTER = 0xFFFF
const.LEFT = 0xFFFE
const.RIGHT = 0xFFFD
const.MOUSEPOS = 0xFFFC
const.CURRENT = 0xFFFB
const.CENTERPARENT = 0xFFFA
const.TOP = const.LEFT
const.BOTTOM = const.RIGHT

-- enum{IUP_SHOW, IUP_RESTORE, IUP_MINIMIZE, IUP_MAXIMIZE, IUP_HIDE};

-- enum{IUP_SBUP,   IUP_SBDN,    IUP_SBPGUP,   IUP_SBPGDN,    IUP_SBPOSV, IUP_SBDRAGV,
--      IUP_SBLEFT, IUP_SBRIGHT, IUP_SBPGLEFT, IUP_SBPGRIGHT, IUP_SBPOSH, IUP_SBDRAGH};

const.BUTTON1 = '1'
const.BUTTON2 = '2'
const.BUTTON3 = '3'
const.BUTTON4 = '4'
const.BUTTON5 = '5'

const.MASK_FLOAT = '[+/-]?(/d+/.?/d*|/./d+)'
const.MASK_UFLOAT = '(/d+/.?/d*|/./d+)'
const.MASK_EFLOAT = '[+/-]?(/d+/.?/d*|/./d+)([eE][+/-]?/d+)?'
const.MASK_INT = '[+/-]?/d+'
const.MASK_UINT = '/d+'

const.GETPARAM_OK = -1
const.GETPARAM_INIT = -2
const.GETPARAM_CANCEL = -3
const.GETPARAM_HELP = -4

-- Keyboard codes

const.K_SP = 32
const.K_exclam = 33
const.K_quotedbl = 34
const.K_numbersign = 35
const.K_dollar = 36
const.K_percent = 37
const.K_ampersand = 38
const.K_apostrophe = 39
const.K_parentleft = 40
const.K_parentright = 41
const.K_asterisk = 42
const.K_plus = 43
const.K_comma = 44
const.K_minus = 45
const.K_period = 46
const.K_slash = 47
const.K_0 = 48
const.K_1 = 49
const.K_2 = 50
const.K_3 = 51
const.K_4 = 52
const.K_5 = 53
const.K_6 = 54
const.K_7 = 55
const.K_8 = 56
const.K_9 = 57
const.K_colon = 58
const.K_semicolon = 59
const.K_less = 60
const.K_equal = 61
const.K_greater = 62
const.K_question = 63
const.K_at = 64
const.K_A = 65
const.K_B = 66
const.K_C = 67
const.K_D = 68
const.K_E = 69
const.K_F = 70
const.K_G = 71
const.K_H = 72
const.K_I = 73
const.K_J = 74
const.K_K = 75
const.K_L = 76
const.K_M = 77
const.K_N = 78
const.K_O = 79
const.K_P = 80
const.K_Q = 81
const.K_R = 82
const.K_S = 83
const.K_T = 84
const.K_U = 85
const.K_V = 86
const.K_W = 87
const.K_X = 88
const.K_Y = 89
const.K_Z = 90
const.K_bracketleft = 91
const.K_backslash = 92
const.K_bracketright = 93
const.K_circum = 94
const.K_underscore = 95
const.K_grave = 96
const.K_a = 97
const.K_b = 98
const.K_c = 99
const.K_d = 100
const.K_e = 101
const.K_f = 102
const.K_g = 103
const.K_h = 104
const.K_i = 105
const.K_j = 106
const.K_k = 107
const.K_l = 108
const.K_m = 109
const.K_n = 110
const.K_o = 111
const.K_p = 112
const.K_q = 113
const.K_r = 114
const.K_s = 115
const.K_t = 116
const.K_u = 117
const.K_v = 118
const.K_w = 119
const.K_x = 120
const.K_y = 121
const.K_z = 122
const.K_braceleft = 123
const.K_bar = 124
const.K_braceright = 125
const.K_tilde = 126

const.K_ccedilla = 231
const.K_Ccedilla = 199
const.K_acute = 180
const.K_diaeresis = 168

const.K_quoteleft = const.K_grave
const.K_quoteright = const.K_apostrophe

const.K_BS = 8
const.K_TAB = 9
const.K_CR = 13

const.K_PAUSE = 0xFF13
const.K_ESC = 0xFF1B
const.K_HOME = 0xFF50
const.K_LEFT = 0xFF51
const.K_UP = 0xFF52
const.K_RIGHT = 0xFF53
const.K_DOWN = 0xFF54
const.K_PGUP = 0xFF55
const.K_PGDN = 0xFF56
const.K_END = 0xFF57
const.K_MIDDLE = 0xFF0B
const.K_Print = 0xFF61
const.K_INS = 0xFF63
const.K_Menu = 0xFF67
const.K_DEL = 0xFFFF
const.K_F1 = 0xFFBE
const.K_F2 = 0xFFBF
const.K_F3 = 0xFFC0
const.K_F4 = 0xFFC1
const.K_F5 = 0xFFC2
const.K_F6 = 0xFFC3
const.K_F7 = 0xFFC4
const.K_F8 = 0xFFC5
const.K_F9 = 0xFFC6
const.K_F10 = 0xFFC7
const.K_F11 = 0xFFC8
const.K_F12 = 0xFFC9

const.K_LSHIFT = 0xFFE1
const.K_RSHIFT = 0xFFE2
const.K_LCTRL = 0xFFE3
const.K_RCTRL = 0xFFE4
const.K_LALT = 0xFFE9
const.K_RALT = 0xFFEA

const.K_NUM = 0xFF7F
const.K_SCROLL = 0xFF14
const.K_CAPS = 0xFFE5

-- local function get_const(value)
--   if type(value) == 'string' then
--     if const[value] then
--       return const[value]
--     else
--       error('unknown const name', 3)
--     end
--   end

--   return value
-- end

local header = [[
  typedef struct Ihandle_ Ihandle;
  typedef int (*Icallback)(Ihandle*);

  typedef int (*Iparamcb)(Ihandle* dialog, int param_index, void* user_data);

  int       IupOpen          (int *argc, char ***argv);
  void      IupClose         (void);
  void      IupImageLibOpen  (void);

  int       IupMainLoop      (void);
  int       IupLoopStep      (void);
  int       IupLoopStepWait  (void);
  int       IupMainLoopLevel (void);
  void      IupFlush         (void);
  void      IupExitLoop      (void);

  int       IupRecordInput(const char* filename, int mode);
  int       IupPlayInput(const char* filename);

  void      IupUpdate        (Ihandle* ih);
  void      IupUpdateChildren(Ihandle* ih);
  void      IupRedraw        (Ihandle* ih, int children);
  void      IupRefresh       (Ihandle* ih);
  void      IupRefreshChildren(Ihandle* ih);

  int       IupHelp          (const char* url);
  char*     IupLoad          (const char *filename);
  char*     IupLoadBuffer    (const char *buffer);

  char*     IupVersion       (void);
  char*     IupVersionDate   (void);
  int       IupVersionNumber (void);

  void      IupSetLanguage   (const char *lng);
  char*     IupGetLanguage   (void);
  void      IupSetLanguageString(const char* name, const char* str);
  void      IupStoreLanguageString(const char* name, const char* str);
  char*     IupGetLanguageString(const char* name);
  void      IupSetLanguagePack(Ihandle* ih);

  void      IupDestroy      (Ihandle* ih);
  void      IupDetach       (Ihandle* child);
  Ihandle*  IupAppend       (Ihandle* ih, Ihandle* child);
  Ihandle*  IupInsert       (Ihandle* ih, Ihandle* ref_child, Ihandle* child);
  Ihandle*  IupGetChild     (Ihandle* ih, int pos);
  int       IupGetChildPos  (Ihandle* ih, Ihandle* child);
  int       IupGetChildCount(Ihandle* ih);
  Ihandle*  IupGetNextChild (Ihandle* ih, Ihandle* child);
  Ihandle*  IupGetBrother   (Ihandle* ih);
  Ihandle*  IupGetParent    (Ihandle* ih);
  Ihandle*  IupGetDialog    (Ihandle* ih);
  Ihandle*  IupGetDialogChild(Ihandle* ih, const char* name);
  int       IupReparent     (Ihandle* ih, Ihandle* new_parent, Ihandle* ref_child);

  int       IupPopup         (Ihandle* ih, int x, int y);
  int       IupShow          (Ihandle* ih);
  int       IupShowXY        (Ihandle* ih, int x, int y);
  int       IupHide          (Ihandle* ih);
  int       IupMap           (Ihandle* ih);
  void      IupUnmap         (Ihandle *ih);

  void      IupResetAttribute(Ihandle *ih, const char* name);
  int       IupGetAllAttributes(Ihandle* ih, char** names, int n);
  Ihandle*  IupSetAtt(const char* handle_name, Ihandle* ih, const char* name, ...);
  Ihandle*  IupSetAttributes (Ihandle* ih, const char *str);
  char*     IupGetAttributes (Ihandle* ih);

  void      IupSetAttribute   (Ihandle* ih, const char* name, const char* value);
  void      IupSetStrAttribute(Ihandle* ih, const char* name, const char* value);
  void      IupSetStrf        (Ihandle* ih, const char* name, const char* format, ...);
  void      IupSetInt         (Ihandle* ih, const char* name, int value);
  void      IupSetFloat       (Ihandle* ih, const char* name, float value);
  void      IupSetDouble      (Ihandle* ih, const char* name, double value);
  void      IupSetRGB         (Ihandle *ih, const char* name, unsigned char r, unsigned char g, unsigned char b);

  void      IupStoreAttribute   (Ihandle* ih, const char* name, const char* value);
  void      IupStoreAttributeId (Ihandle* ih, const char* name, int id, const char* value);
  void      IupStoreAttributeId2(Ihandle* ih, const char* name, int lin, int col, const char* value);

  char*     IupGetAttribute(Ihandle* ih, const char* name);
  int       IupGetInt      (Ihandle* ih, const char* name);
  int       IupGetInt2     (Ihandle* ih, const char* name);
  int       IupGetIntInt   (Ihandle *ih, const char* name, int *i1, int *i2);
  float     IupGetFloat    (Ihandle* ih, const char* name);
  double    IupGetDouble(Ihandle* ih, const char* name);
  void      IupGetRGB      (Ihandle *ih, const char* name, unsigned char *r, unsigned char *g, unsigned char *b);

  void  IupSetAttributeId(Ihandle *ih, const char* name, int id, const char *value);
  void  IupSetStrAttributeId(Ihandle *ih, const char* name, int id, const char *value);
  void  IupSetStrfId(Ihandle *ih, const char* name, int id, const char* format, ...);
  void  IupSetIntId(Ihandle* ih, const char* name, int id, int value);
  void  IupSetFloatId(Ihandle* ih, const char* name, int id, float value);
  void  IupSetDoubleId(Ihandle* ih, const char* name, int id, double value);
  void  IupSetRGBId(Ihandle *ih, const char* name, int id, unsigned char r, unsigned char g, unsigned char b);

  char*  IupGetAttributeId(Ihandle *ih, const char* name, int id);
  int    IupGetIntId(Ihandle *ih, const char* name, int id);
  float  IupGetFloatId(Ihandle *ih, const char* name, int id);
  double IupGetDoubleId(Ihandle *ih, const char* name, int id);
  void   IupGetRGBId(Ihandle *ih, const char* name, int id, unsigned char *r, unsigned char *g, unsigned char *b);

  void  IupSetAttributeId2(Ihandle* ih, const char* name, int lin, int col, const char* value);
  void  IupSetStrAttributeId2(Ihandle* ih, const char* name, int lin, int col, const char* value);
  void  IupSetStrfId2(Ihandle* ih, const char* name, int lin, int col, const char* format, ...);
  void  IupSetIntId2(Ihandle* ih, const char* name, int lin, int col, int value);
  void  IupSetFloatId2(Ihandle* ih, const char* name, int lin, int col, float value);
  void  IupSetDoubleId2(Ihandle* ih, const char* name, int lin, int col, double value);
  void  IupSetRGBId2(Ihandle *ih, const char* name, int lin, int col, unsigned char r, unsigned char g, unsigned char b);

  char*  IupGetAttributeId2(Ihandle* ih, const char* name, int lin, int col);
  int    IupGetIntId2(Ihandle* ih, const char* name, int lin, int col);
  float  IupGetFloatId2(Ihandle* ih, const char* name, int lin, int col);
  double IupGetDoubleId2(Ihandle* ih, const char* name, int lin, int col);
  void   IupGetRGBId2(Ihandle *ih, const char* name, int lin, int col, unsigned char *r, unsigned char *g, unsigned char *b);

  void      IupSetGlobal  (const char* name, const char* value);
  void      IupSetStrGlobal(const char* name, const char* value);
  char*     IupGetGlobal  (const char* name);

  Ihandle*  IupSetFocus     (Ihandle* ih);
  Ihandle*  IupGetFocus     (void);
  Ihandle*  IupPreviousField(Ihandle* ih);
  Ihandle*  IupNextField    (Ihandle* ih);

  Icallback IupGetCallback (Ihandle* ih, const char *name);
  Icallback IupSetCallback (Ihandle* ih, const char *name, Icallback func);
  Ihandle*  IupSetCallbacks(Ihandle* ih, const char *name, Icallback func, ...);

  Icallback IupGetFunction(const char *name);
  Icallback IupSetFunction(const char *name, Icallback func);

  Ihandle*  IupGetHandle    (const char *name);
  Ihandle*  IupSetHandle    (const char *name, Ihandle* ih);
  int       IupGetAllNames  (char** names, int n);
  int       IupGetAllDialogs(char** names, int n);
  char*     IupGetName      (Ihandle* ih);

  void      IupSetAttributeHandle(Ihandle* ih, const char* name, Ihandle* ih_named);
  Ihandle*  IupGetAttributeHandle(Ihandle* ih, const char* name);

  char*     IupGetClassName(Ihandle* ih);
  char*     IupGetClassType(Ihandle* ih);
  int       IupGetAllClasses(char** names, int n);
  int       IupGetClassAttributes(const char* classname, char** names, int n);
  int       IupGetClassCallbacks(const char* classname, char** names, int n);
  void      IupSaveClassAttributes(Ihandle* ih);
  void      IupCopyClassAttributes(Ihandle* src_ih, Ihandle* dst_ih);
  void      IupSetClassDefaultAttribute(const char* classname, const char *name, const char* value);
  int       IupClassMatch(Ihandle* ih, const char* classname);

  Ihandle*  IupCreate (const char *classname);
  Ihandle*  IupCreatev(const char *classname, void* *params);
  Ihandle*  IupCreatep(const char *classname, void *first, ...);

  /************************************************************************/
  /*                        Elements                                      */
  /************************************************************************/

  Ihandle*  IupFill       (void);
  Ihandle*  IupRadio      (Ihandle* child);
  Ihandle*  IupVbox       (Ihandle* child, ...);
  Ihandle*  IupVboxv      (Ihandle* *children);
  Ihandle*  IupZbox       (Ihandle* child, ...);
  Ihandle*  IupZboxv      (Ihandle* *children);
  Ihandle*  IupHbox       (Ihandle* child,...);
  Ihandle*  IupHboxv      (Ihandle* *children);

  Ihandle*  IupNormalizer (Ihandle* ih_first, ...);
  Ihandle*  IupNormalizerv(Ihandle* *ih_list);

  Ihandle*  IupCbox       (Ihandle* child, ...);
  Ihandle*  IupCboxv      (Ihandle* *children);
  Ihandle*  IupSbox       (Ihandle *child);
  Ihandle*  IupSplit      (Ihandle* child1, Ihandle* child2);
  Ihandle*  IupScrollBox  (Ihandle* child);
  Ihandle*  IupGridBox    (Ihandle* child, ...);
  Ihandle*  IupGridBoxv   (Ihandle **children);
  Ihandle*  IupExpander   (Ihandle *child);
  Ihandle*  IupDetachBox  (Ihandle *child);
  Ihandle*  IupBackgroundBox(Ihandle *child);

  Ihandle*  IupFrame      (Ihandle* child);

  Ihandle*  IupImage      (int width, int height, const unsigned char *pixmap);
  Ihandle*  IupImageRGB   (int width, int height, const unsigned char *pixmap);
  Ihandle*  IupImageRGBA  (int width, int height, const unsigned char *pixmap);

  Ihandle*  IupItem       (const char* title, const char* action);
  Ihandle*  IupSubmenu    (const char* title, Ihandle* child);
  Ihandle*  IupSeparator  (void);
  Ihandle*  IupMenu       (Ihandle* child,...);
  Ihandle*  IupMenuv      (Ihandle* *children);

  Ihandle*  IupButton     (const char* title, const char* action);
  Ihandle*  IupCanvas     (const char* action);
  Ihandle*  IupDialog     (Ihandle* child);
  Ihandle*  IupUser       (void);
  Ihandle*  IupLabel      (const char* title);
  Ihandle*  IupList       (const char* action);
  Ihandle*  IupText       (const char* action);
  Ihandle*  IupMultiLine  (const char* action);
  Ihandle*  IupToggle     (const char* title, const char* action);
  Ihandle*  IupTimer      (void);
  Ihandle*  IupClipboard  (void);
  Ihandle*  IupProgressBar(void);
  Ihandle*  IupVal        (const char *type);
  Ihandle*  IupTabs       (Ihandle* child, ...);
  Ihandle*  IupTabsv      (Ihandle* *children);
  Ihandle*  IupTree       (void);
  Ihandle*  IupLink       (const char* url, const char* title);


  /************************************************************************/
  /*                      Utilities                                       */
  /************************************************************************/

  /* IupImage utility */
  int IupSaveImageAsText(Ihandle* ih, const char* file_name, const char* format, const char* name);

  /* IupText and IupScintilla utilities */
  void  IupTextConvertLinColToPos(Ihandle* ih, int lin, int col, int *pos);
  void  IupTextConvertPosToLinCol(Ihandle* ih, int pos, int *lin, int *col);

  /* IupText, IupList, IupTree, IupMatrix and IupScintilla utility */
  int   IupConvertXYToPos(Ihandle* ih, int x, int y);

  /* IupTree utilities */
  int   IupTreeSetUserId(Ihandle* ih, int id, void* userid);
  void* IupTreeGetUserId(Ihandle* ih, int id);
  int   IupTreeGetId(Ihandle* ih, void *userid);
  void  IupTreeSetAttributeHandle(Ihandle* ih, const char* name, int id, Ihandle* ih_named);


  /************************************************************************/
  /*                      Pre-definided dialogs                           */
  /************************************************************************/

  Ihandle* IupFileDlg(void);
  Ihandle* IupMessageDlg(void);
  Ihandle* IupColorDlg(void);
  Ihandle* IupFontDlg(void);
  Ihandle* IupProgressDlg(void);

  int  IupGetFile(char *arq);
  void IupMessage(const char *title, const char *msg);
  void IupMessagef(const char *title, const char *format, ...);
  int  IupAlarm(const char *title, const char *msg, const char *b1, const char *b2, const char *b3);
  int  IupScanf(const char *format, ...);
  int  IupListDialog(int type, const char *title, int size, const char** list,
                     int op, int max_col, int max_lin, int* marks);
  int  IupGetText(const char* title, char* text);
  int  IupGetColor(int x, int y, unsigned char* r, unsigned char* g, unsigned char* b);

  int IupGetParam(const char* title, Iparamcb action, void* user_data, const char* format,...);
  int IupGetParamv(const char* title, Iparamcb action, void* user_data, const char* format, int param_count, int param_extra, void** param_data);

  Ihandle* IupLayoutDialog(Ihandle* dialog);
  Ihandle* IupElementPropertiesDialog(Ihandle* elem);
]]

local bind = {}
local help = {}
local mod = {}

mod.stored_callbacks = {}

-- cap as in c

function mod.Open()
  -- skip argc and argv
  return bind.IupOpen(nil, nil)
end

function mod.Close()
  bind.IupClose()
end

function mod.ImageLibOpen()
  bind.IupImageLibOpen()
end

function mod.MainLoop()
  return bind.IupMainLoop()
end

function mod.LoopStep()
  return bind.IupLoopStep()
end

function mod.LoopStepWait()
  return bind.IupLoopStepWait()
end

function mod.MainLoopLevel()
  return bind.IupMainLoopLevel()
end

function mod.Flush()
  bind.IupFlush()
end

function mod.ExitLoop()
  bind.IupExitLoop()
end

function mod.RecordInput(filename, mode)
  return bind.IupRecordInput(filename, mode)
end

function mod.PlayInput(filename)
  return bind.IupPlayInput(filename)
end

function mod.Update(ih)
  bind.IupUpdate(ih)
end

function mod.UpdateChildren(ih)
  bind.IupUpdateChildren(ih)
end

function mod.Redraw(ih, children)
  bind.IupRedraw(ih, children)
end

function mod.Refresh(ih)
  bind.IupRefresh(ih)
end

function mod.RefreshChildren(ih)
  bind.IupRefreshChildren(ih)
end

function mod.Help(url)
  return bind.IupHelp(url)
end

function mod.Load(filename)
  local err = bind.IupLoad(filename)
  return (err ~= nil) and ffi.string(err) or nil
end

function mod.LoadBuffer(buffer)
  local err = bind.IupLoadBuffer(buffer)
  return (err ~= nil) and ffi.string(err) or nil
end

function mod.Version()
  return ffi.string(bind.IupVersion())
end

function mod.VersionDate()
  return ffi.string(bind.IupVersionDate())
end

function mod.VersionNumber()
  return bind.IupVersionNumber()
end

function mod.SetLanguage(lng)
  bind.IupSetLanguage(lng)
end

function mod.GetLanguage()
  return ffi.string(bind.IupGetLanguage())
end

function mod.SetLanguageString(name, str)
  bind.IupSetLanguageString(name, str)
end

function mod.StoreLanguageString(name, str)
  bind.IupStoreLanguageString(name, str)
end

function mod.GetLanguageString(name)
  return ffi.string(bind.IupGetLanguageString(name))
end

function mod.SetLanguagePack(ih)
  bind.IupSetLanguagePack(ih)
end

function mod.Destroy(ih)
  bind.IupDestroy(ih)
end

function mod.Detach(child)
  bind.IupDetach(child)
end

function mod.Append(ih, child)
  return bind.IupAppend(ih, child)
end

function mod.Insert(ih, ref_child, child)
  return bind.IupInsert(ih, ref_child, child)
end

function mod.GetChild(ih, pos)
  return bind.IupGetChild(ih, pos)
end

function mod.GetChildPos(ih, child)
  return bind.IupGetChildPos(ih, child)
end

function mod.GetChildCount(ih)
  return bind.IupGetChildCount(ih)
end

function mod.GetNextChild(ih, child)
  return bind.IupGetNextChild(ih, child)
end

function mod.GetBrother(ih)
  return bind.IupGetBrother(ih)
end

function mod.GetParent(ih)
  return bind.IupGetParent(ih)
end

function mod.GetDialog(ih)
  return bind.IupGetDialog(ih)
end

function mod.GetDialogChild(ih, name)
  return bind.IupGetDialogChild(ih, name)
end

function mod.Reparent(ih, new_parent, ref_child)
  return bind.IupReparent(ih, new_parent, ref_child)
end

function mod.Popup(ih, x, y)
  return bind.IupPopup(ih, x, y)
end

function mod.Show(ih)
  return bind.IupShow(ih)
end

function mod.ShowXY(ih, x, y)
  return bind.IupShowXY(ih, x, y)
end

function mod.Hide(ih)
  return bind.IupHide(ih)
end

function mod.Map(ih)
  return bind.IupMap(ih)
end

function mod.Unmap(ih)
  bind.IupUnmap(ih)
end

function mod.ResetAttribute(ih, name)
  bind.IupResetAttribute(ih, name)
end

function mod.GetAllAttributes(ih)
  local count = bind.IupGetAllAttributes(ih, nil, 0)
  local cdata = ffi.new('char*[?]', count)

  bind.IupGetAllAttributes(ih, cdata, count)

  local attributes = {}
  for i = 0, count - 1 do
    -- invalid count fix
    if cdata[i] ~= nil then
      table.insert(attributes, ffi.string(cdata[i]))
    end
  end

  return attributes
end

function mod.SetAtt(handle_name, ih, name, ...)
  name = help.attrname(name)
  return bind.IupSetAtt(handle_name, ih, name, help.vararg(...))
end

function mod.SetAttributes(ih, str)
  return bind.IupSetAttributes(ih, str)
end

function mod.GetAttributes(ih)
  return ffi.string(bind.IupGetAttributes(ih))
end

function mod.SetAttribute(ih, name, value_or_format, ...)
  name = help.attrname(name)

  local value
  if select("#", ...) == 0 then
    value = help.attrvalue(value_or_format)
  else
    value = string.format(value_or_format, ...)
  end

  bind.IupStoreAttribute(ih, name, value)
end

function mod.SetStrAttribute(ih, name, value)
  name = help.attrname(name)
  bind.IupSetStrAttribute(ih, name, value)
end

function mod.SetInt(ih, name, value)
  name = help.attrname(name)
  bind.IupSetInt(ih, name, value)
end

function mod.SetFloat(ih, name, value)
  name = help.attrname(name)
  bind.IupSetFloat(ih, name, value)
end

function mod.SetDouble(ih, name, value)
  name = help.attrname(name)
  bind.IupSetDouble(ih, name, value)
end

function mod.SetRGB(ih, name, r, g, b)
  name = help.attrname(name)
  bind.IupSetRGB(ih, name, r, g, b)
end

function mod.GetAttribute(ih, name)
  name = help.attrname(name)
  return ffi.string(bind.IupGetAttribute(ih, name))
end

function mod.GetInt(ih, name)
  name = help.attrname(name)
  return bind.IupGetInt(ih, name)
end

function mod.GetInt2(ih, name)
  name = help.attrname(name)
  return bind.IupGetInt2(ih, name)
end

function mod.GetIntInt(ih, name)
  name = help.attrname(name)

  local i1 = ffi.new('int[1]')
  local i2 = ffi.new('int[1]')

  bind.IupGetIntInt(ih, name, i1, i2)

  return i1[0], i2[0]
end

function mod.GetFloat(ih, name)
  name = help.attrname(name)
  return bind.IupGetFloat(ih, name)
end

function mod.GetDouble(ih, name)
  name = help.attrname(name)
  return bind.IupGetDouble(ih, name)
end

function mod.GetRGB(ih, name)
  name = help.attrname(name)

  local r = ffi.new('unsigned char[1]')
  local g = ffi.new('unsigned char[1]')
  local b = ffi.new('unsigned char[1]')

  bind.IupGetRGB(ih, name, r, g, b)

  return r[0], g[0], b[0]
end

function mod.SetAttributeId(ih, name, id, value_or_format, ...)
  name = help.attrname(name)
  local value

  if select("#", ...) == 0 then
    value = value_or_format
  else
    value = string.format(value_or_format, ...)
  end

  bind.IupStoreAttributeId(ih, name, id, value)
end

function mod.SetStrAttributeId(ih, name, id, value)
  name = help.attrname(name)
  bind.IupSetStrAttributeId(ih, name, id, value)
end

function mod.SetIntId(ih, name, id, value)
  name = help.attrname(name)
  bind.IupSetIntId(ih, name, id, value)
end

function mod.SetFloatId(ih, name, id, value)
  name = help.attrname(name)
  bind.IupSetFloatId(ih, name, id, value)
end

function mod.SetDoubleId(ih, name, id, value)
  name = help.attrname(name)
  bind.IupSetDoubleId(ih, name, id, value)
end

function mod.SetRGBId(ih, name, id, r, g, b)
  name = help.attrname(name)
  bind.IupSetRGBId(ih, name, id, r, g, b)
end

function mod.GetAttributeId(ih, name, id)
  name = help.attrname(name)
  return ffi.string(bind.IupGetAttributeId(ih, name, id))
end

function mod.GetIntId(ih, name, id)
  name = help.attrname(name)
  return bind.IupGetIntId(ih, name, id)
end

function mod.GetFloatId(ih, name, id)
  name = help.attrname(name)
  return bind.IupGetFloatId(ih, name, id)
end

function mod.GetDoubleId(ih, name, id)
  name = help.attrname(name)
  return bind.IupGetDoubleId(ih, name, id)
end

function mod.GetRGBId(ih, name, id)
  name = help.attrname(name)

  local r = ffi.new('unsigned char[1]')
  local g = ffi.new('unsigned char[1]')
  local b = ffi.new('unsigned char[1]')

  bind.IupGetRGBId(ih, name, id, r, g, b)

  return r[0], g[0], b[0]
end

function mod.SetAttributeId2(ih, name, lin, col, value)
  name = help.attrname(name)
  bind.IupStoreAttributeId2(ih, name, lin, col, value)
end

function mod.SetStrAttributeId2(ih, name, lin, col, value)
  name = help.attrname(name)
  bind.IupSetStrAttributeId2(ih, name, lin, col, value)
end

function mod.SetStrfId2(ih, name, lin, col, format, ...)
  name = help.attrname(name)
  local value = string.format(format, ...)
  bind.IupStoreAttributeId2(ih, name, lin, col, value)
end

function mod.SetIntId2(ih, name, lin, col, value)
  name = help.attrname(name)
  bind.IupSetIntId2(ih, name, lin, col, value)
end

function mod.SetFloatId2(ih, name, lin, col, value)
  name = help.attrname(name)
  bind.IupSetFloatId2(ih, name, lin, col, value)
end

function mod.SetDoubleId2(ih, name, lin, col, value)
  name = help.attrname(name)
  bind.IupSetDoubleId2(ih, name, lin, col, value)
end

function mod.SetRGBId2(ih, name, lin, col, r, g, b)
  name = help.attrname(name)
  bind.IupSetRGBId2(ih, name, lin, col, r, g, b)
end

function mod.GetAttributeId2(ih, name, lin, col)
  name = help.attrname(name)
  return ffi.string(bind.IupGetAttributeId2(ih, name, lin, col))
end

function mod.GetIntId2(ih, name, lin, col)
  name = help.attrname(name)
  return bind.IupGetIntId2(ih, name, lin, col)
end

function mod.GetFloatId2(ih, name, lin, col)
  name = help.attrname(name)
  return bind.IupGetFloatId2(ih, name, lin, col)
end

function mod.GetDoubleId2(ih, name, lin, col)
  name = help.attrname(name)
  return bind.IupGetDoubleId2(ih, name, lin, col)
end

function mod.GetRGBId2(ih, name, lin, col)
  name = help.attrname(name)

  local r = ffi.new('unsigned char[1]')
  local g = ffi.new('unsigned char[1]')
  local b = ffi.new('unsigned char[1]')

  bind.IupGetRGBId2(ih, name, lin, col, r, g, b)

  return r[0], g[0], b[0]
end

function mod.SetGlobal(name, value)
  name = help.attrname(name)
  bind.IupSetGlobal(name, value)
end

function mod.SetStrGlobal(name, value)
  name = help.attrname(name)
  bind.IupSetStrGlobal(name, value)
end

function mod.GetGlobal(name)
  name = help.attrname(name)
  return ffi.string(bind.IupGetGlobal(name))
end

function mod.SetFocus(ih)
  return bind.IupSetFocus(ih)
end

function mod.GetFocus()
  return bind.IupGetFocus()
end

function mod.PreviousField(ih)
  return bind.IupPreviousField(ih)
end

function mod.NextField(ih)
  return bind.IupNextField(ih)
end

function mod.GetCallback(ih, name)
  name = help.attrname(name)
  return bind.IupGetCallback(ih, name)
end

function mod.SetCallback(ih, name, func)
  name = help.attrname(name)

  -- Initialize storage for this handle if needed
  mod.stored_callbacks[ih] = mod.stored_callbacks[ih] or {}

  -- Free previous callback for this handle and name if exists
  if mod.stored_callbacks[ih][name] then
    mod.stored_callbacks[ih][name]:free()
    mod.stored_callbacks[ih][name] = nil
  end

  -- Cast the Lua function to ffi callback
  local cb = ffi.cast('Icallback', func)

  -- Store the casted callback to free later
  mod.stored_callbacks[ih][name] = cb

  -- Set the callback on the IUP handle
  return bind.IupSetCallback(ih, name, cb)
end

function mod.FreeCallbacks(ih)
  if ih then
    -- Free callbacks for a specific handle
    if mod.stored_callbacks[ih] then
      for _, cb in pairs(mod.stored_callbacks[ih]) do
        if type(cb) == "cdata" and ffi.istype("Icallback", cb) and cb.free then
          cb:free()
        end
      end
      mod.stored_callbacks[ih] = nil
    end
  elseif type(ih) == 'table' then
    for _, handle in pairs(ih) do
      mod.FreeCallbacks(handle)
    end
  elseif ih == nil then
    -- Free all callbacks for all handles
    for handle, callbacks in pairs(mod.stored_callbacks) do
      for _, cb in pairs(callbacks) do
        if type(cb) == "cdata" and ffi.istype("Icallback", cb) and cb.free then
          cb:free()
        end
      end
      mod.stored_callbacks[handle] = nil
    end
  end
end

function mod.SetCallbacks(ih, name, func, ...)
  --  Ihandle* IupSetCallbacks(Ihandle* ih, const char *name, Icallback func, ...)
  return bind.IupSetCallbacks(ih, name, func, ...)
end

function mod.GetFunction(name)
  name = help.attrname(name)
  return bind.IupGetFunction(name)
end

function mod.SetFunction(name, func)
  --  Icallback IupSetFunction(const char *name, Icallback func)
  name = help.attrname(name)
  return bind.IupSetFunction(name, func)
end

function mod.GetHandle(name)
  return bind.IupGetHandle(name)
end

function mod.SetHandle(name, ih)
  return bind.IupSetHandle(name, ih)
end

function mod.GetAllNames()
  local count = bind.IupGetAllNames(nil, 0)
  local cdata = ffi.new('char*[?]', count)

  bind.IupGetAllNames(cdata, count)

  local names = {}
  for i = 0, count - 1 do
    table.insert(names, ffi.string(cdata[i]))
  end

  return names
end

function mod.GetAllDialogs()
  local count = bind.IupGetAllDialogs(nil, 0)
  local cdata = ffi.new('char*[?]', count)

  bind.IupGetAllDialogs(cdata, count)

  local dialogs = {}
  for i = 0, count - 1 do
    table.insert(dialogs, ffi.string(cdata[i]))
  end

  return dialogs
end

function mod.GetName(ih)
  local r = bind.IupGetName(ih)
  return (r ~= nil) and ffi.string(r) or nil
end

function mod.SetAttributeHandle(ih, name, ih_named)
  name = help.attrname(name)
  bind.IupSetAttributeHandle(ih, name, ih_named)
end

function mod.GetAttributeHandle(ih, name)
  name = help.attrname(name)
  return bind.IupGetAttributeHandle(ih, name)
end

function mod.GetClassName(ih)
  return ffi.string(bind.IupGetClassName(ih))
end

function mod.GetClassType(ih)
  return ffi.string(bind.IupGetClassType(ih))
end

function mod.GetAllClasses()
  local count = bind.IupGetAllClasses(nil, 0)
  local cdata = ffi.new('char*[?]', count)

  bind.IupGetAllClasses(cdata, count)

  local classes = {}
  for i = 0, count - 1 do
    table.insert(classes, ffi.string(cdata[i]))
  end

  return classes
end

function mod.GetClassAttributes(classname)
  local count = bind.IupGetClassAttributes(classname, nil, 0)

  -- class not found
  if count == -1 then
    return
  end

  local cdata = ffi.new('char*[?]', count)

  bind.IupGetClassAttributes(classname, cdata, count)

  local attributes = {}
  for i = 0, count - 1 do
    -- invalid count fix
    if cdata[i] ~= nil then
      table.insert(attributes, ffi.string(cdata[i]))
    end
  end

  return attributes
end

function mod.GetClassCallbacks(classname)
  local count = bind.IupGetClassCallbacks(classname, nil, 0)

  -- class not found
  if count == -1 then
    return
  end

  local cdata = ffi.new('char*[?]', count)

  bind.IupGetClassCallbacks(classname, cdata, count)

  local callbacks = {}
  for i = 0, count - 1 do
    -- invalid count fix
    if cdata[i] ~= nil then
      table.insert(callbacks, ffi.string(cdata[i]))
    end
  end

  return callbacks
end

function mod.SaveClassAttributes(ih)
  bind.IupSaveClassAttributes(ih)
end

function mod.CopyClassAttributes(src_ih, dst_ih)
  bind.IupCopyClassAttributes(src_ih, dst_ih)
end

function mod.SetClassDefaultAttribute(classname, name, value)
  name = help.attrname(name)
  bind.IupSetClassDefaultAttribute(classname, name, value)
end

function mod.ClassMatch(ih, classname)
  return bind.IupClassMatch(ih, classname)
end

function mod.Create(classname)
  return bind.IupCreate(classname)
end

function mod.Createv(classname, params)
  params = help.vararr('void*', params)
  return bind.IupCreatev(classname, params)
end

function mod.Createp(classname, first, ...)
  return bind.IupCreatep(classname, first, help.vararg(...))
end

-- element all lower but without _

function mod.fill()
  return bind.IupFill()
end

function mod.radio(child)
  return bind.IupRadio(child)
end

function mod.vbox(child, ...)
  return bind.IupVbox(child, help.vararg(...))
end

function mod.vboxv(children)
  children = help.vararr('Ihandle*', children)
  return bind.IupVboxv(children)
end

function mod.zbox(child, ...)
  return bind.IupZbox(child, help.vararg(...))
end

function mod.zboxv(children)
  children = help.vararr('Ihandle*', children)
  return bind.IupZboxv(children)
end

function mod.hbox(child, ...)
  return bind.IupHbox(child, help.vararg(...))
end

function mod.hboxv(children)
  children = help.vararr('Ihandle*', children)
  return bind.IupHboxv(children)
end

function mod.normalizer(ih_first, ...)
  return bind.IupNormalizer(ih_first, help.vararg(...))
end

function mod.normalizerv(ih_list)
  ih_list = help.vararr('Ihandle*', ih_list)
  return bind.IupNormalizerv(ih_list)
end

function mod.cbox(child, ...)
  return bind.IupCbox(child, help.vararg(...))
end

function mod.cboxv(children)
  children = help.vararr('Ihandle*', children)
  return bind.IupCboxv(children)
end

function mod.sbox(child)
  return bind.IupSbox(child)
end

function mod.split(child1, child2)
  return bind.IupSplit(child1, child2)
end

function mod.scrollbox(child)
  return bind.IupScrollBox(child)
end

function mod.gridbox(child, ...)
  return bind.IupGridBox(child, help.vararg(...))
end

function mod.gridboxv(children)
  children = help.vararr('Ihandle*', children)
  return bind.IupGridBoxv(children)
end

function mod.expander(child)
  return bind.IupExpander(child)
end

function mod.detachbox(child)
  return bind.IupDetachBox(child)
end

function mod.backgroundbox(child)
  return bind.IupBackgroundBox(child)
end

function mod.frame(child)
  return bind.IupFrame(child)
end

function mod.image(width, height, pixmap)
  if type(pixmap) == 'table' then
    local size = width * height
    pixmap = ffi.new('const unsigned char[?]', size, pixmap)
  end
  -- iup copy image data, so no need to keep it
  return bind.IupImage(width, height, pixmap)
end

function mod.imagergb(width, height, pixmap)
  if type(pixmap) == 'table' then
    local size = width * height * 3
    pixmap = ffi.new('const unsigned char[?]', size, pixmap)
  end
  -- iup copy image data, so no need to keep it
  return bind.IupImageRGB(width, height, pixmap)
end

function mod.imagergba(width, height, pixmap)
  if type(pixmap) == 'table' then
    local size = width * height * 4
    pixmap = ffi.new('const unsigned char[?]', size, pixmap)
  end
  -- iup copy image data, so no need to keep it
  return bind.IupImageRGBA(width, height, pixmap)
end

function mod.item(title, action)
  return bind.IupItem(title, action)
end

function mod.submenu(title, child)
  return bind.IupSubmenu(title, child)
end

function mod.separator()
  return bind.IupSeparator()
end

function mod.menu(child, ...)
  return bind.IupMenu(child, help.vararg(...))
end

function mod.menuv(children)
  children = help.vararr('Ihandle*', children)
  return bind.IupMenuv(children)
end

function mod.button(title, action)
  return bind.IupButton(title, action)
end

function mod.canvas(action)
  return bind.IupCanvas(action)
end

function mod.dialog(child)
  return bind.IupDialog(child)
end

function mod.user()
  return bind.IupUser()
end

function mod.label(title)
  return bind.IupLabel(title)
end

function mod.list(action)
  return bind.IupList(action)
end

function mod.text(action)
  return bind.IupText(action)
end

function mod.multiline(action)
  return bind.IupMultiLine(action)
end

function mod.toggle(title, action)
  return bind.IupToggle(title, action)
end

function mod.timer()
  return bind.IupTimer()
end

function mod.clipboard()
  return bind.IupClipboard()
end

function mod.progressbar()
  return bind.IupProgressBar()
end

function mod.val(type)
  return bind.IupVal(type)
end

function mod.tabs(child, ...)
  return bind.IupTabs(child, help.vararg(...))
end

function mod.tabsv(children)
  children = help.vararr('Ihandle*', children)
  return bind.IupTabsv(children)
end

function mod.tree()
  return bind.IupTree()
end

function mod.link(url, title)
  return bind.IupLink(url, title)
end

-- func

function mod.SaveImageAsText(ih, file_name, format, name)
  return bind.IupSaveImageAsText(ih, file_name, format, name)
end

function mod.TextConvertLinColToPos(ih, lin, col)
  local pos = ffi.new('int[1]')

  bind.IupTextConvertLinColToPos(ih, lin, col, pos)

  return pos[0]
end

function mod.TextConvertPosToLinCol(ih, pos)
  local lin = ffi.new('int[1]')
  local col = ffi.new('int[1]')

  bind.IupTextConvertPosToLinCol(ih, pos, lin, col)

  return lin[0], col[0]
end

function mod.ConvertXYToPos(ih, x, y)
  return bind.IupConvertXYToPos(ih, x, y)
end

function mod.TreeSetUserId(ih, id, userid)
  return bind.IupTreeSetUserId(ih, id, userid)
end

function mod.TreeGetUserId(ih, id)
  return bind.IupTreeGetUserId(ih, id)
end

function mod.TreeGetId(ih, userid)
  return bind.IupTreeGetId(ih, userid)
end

function mod.TreeSetAttributeHandle(ih, name, id, ih_named)
  name = help.attrname(name)
  bind.IupTreeSetAttributeHandle(ih, name, id, ih_named)
end

-- el dlg

function mod.filedlg()
  return bind.IupFileDlg()
end

function mod.messagedlg()
  return bind.IupMessageDlg()
end

function mod.colordlg()
  return bind.IupColorDlg()
end

function mod.fontdlg()
  return bind.IupFontDlg()
end

function mod.progressdlg()
  return bind.IupProgressDlg()
end

-- func

function mod.GetFile(arq)
  return bind.IupGetFile(arq)
end

function mod.Message(title, format, ...)
  local msg
  if select('#', ...) == 0 then
    msg = format
  else
    msg = string.format(format, ...)
  end
  bind.IupMessage(title, msg)
end

function mod.Alarm(title, msg, b1, b2, b3)
  return bind.IupAlarm(title, msg, b1, b2, b3)
end

-- function mod.ListDialog(type, title, size, list, op, max_col, max_lin, marks)
-- --  int IupListDialog(int type, const char *title, int size, const char** list, int op, int max_col, int max_lin, int* marks)
--   return bind.IupListDialog(type, title, size, list, op, max_col, max_lin, marks)
-- end

function mod.GetText(title, initial_text, max_length)
  max_length = max_length or 10240

  local text_buffer = ffi.new("char[?]", max_length)
  if initial_text then
    local init_str = tostring(initial_text)
    local copy_len = math.min(#init_str, max_length - 1)
    ffi.copy(text_buffer, init_str, copy_len)
  end

  local result = bind.IupGetText(title or "Text Input", text_buffer)

  if result == 1 then
    return true, ffi.string(text_buffer)
  else
    return false, nil
  end
end

-- function mod.GetColor(x, y, r, g, b)
-- --  int IupGetColor(int x, int y, unsigned char* r, unsigned char* g, unsigned char* b)
--   return bind.IupGetColor(x, y, r, g, b)
-- end

-- function mod.GetParam(title, action, user_data, format, ...)
-- --  int IupGetParam(const char* title, Iparamcb action, void* user_data, const char* format,...)
--   return bind.IupGetParam(title, action, user_data, format, ...)
-- end

-- function mod.GetParamv(title, action, user_data, format, param_count, param_extra, param_data)
-- --  int IupGetParamv(const char* title, Iparamcb action, void* user_data, const char* format, int param_count, int param_extra, void** param_data)
--   return bind.IupGetParamv(title, action, user_data, format, param_count, param_extra, param_data)
-- end

-- as func

function mod.LayoutDialog(dialog)
  return bind.IupLayoutDialog(dialog)
end

-- as func

function mod.ElementPropertiesDialog(elem)
  return bind.IupElementPropertiesDialog(elem)
end

function mod.IsShift(s)
  return help.strchar(s, 0) == 'S'
end

function mod.IsControl(s)
  return help.strchar(s, 1) == 'C'
end

function mod.IsDouble(s)
  return help.strchar(s, 5) == 'D'
end

function mod.IsAlt(s)
  return help.strchar(s, 6) == 'A'
end

function mod.IsSys(s)
  return help.strchar(s, 7) == 'Y'
end

function mod.IsButton1(s)
  return help.strchar(s, 2) == '1'
end

function mod.IsButton2(s)
  return help.strchar(s, 3) == '2'
end

function mod.IsButton3(s)
  return help.strchar(s, 4) == '3'
end

function mod.IsButton4(s)
  return help.strchar(s, 8) == '4'
end

function mod.IsButton5(s)
  return help.strchar(s, 9) == '5'
end

-- Keyboard related functions

-- for LuaJIT
local bit = require("bit")

function mod.IsPrint(c)
  return c > 31 and c < 127
end

function mod.IsXKey(c)
  return c >= 128
end

function mod.IsShiftXKey(c)
  return bit.band(c, 0x10000000) ~= 0
end

function mod.IsCtrlXKey(c)
  return bit.band(c, 0x20000000) ~= 0
end

function mod.IsAltXKey(c)
  return bit.band(c, 0x40000000) ~= 0
end

function mod.IsSysXKey(c)
  return bit.band(c, 0x80000000) ~= 0
end

function mod.XKeyBase(c)
  return bit.band(c, 0x0FFFFFFF)
end

function mod.XKeyShift(c)
  return bit.bor(c, 0x10000000)
end

function mod.XKeyCtrl(c)
  return bit.bor(c, 0x20000000)
end

function mod.XKeyAlt(c)
  return bit.bor(c, 0x40000000)
end

function mod.XKeySys(c)
  return bit.bor(c, 0x80000000)
end

-- function mod.IsPrint(c)
--   return c > 31 and c < 127
-- end

-- function mod.IsXKey(c)
--   return c >= 128
-- end

-- function mod.IsShiftXKey(c)
--   return (c & 0x10000000) ~= 0
-- end

-- function mod.IsCtrlXKey(c)
--   return (c & 0x20000000) ~= 0
-- end

-- function mod.IsAltXKey(c)
--   return (c & 0x40000000) ~= 0
-- end

-- function mod.IsSysXKey(c)
--   return (c & 0x80000000) ~= 0
-- end

-- function mod.XKeyBase(c)
--   return c & 0x0FFFFFFF
-- end

-- function mod.XKeyShift(c)
--   return c | 0x10000000
-- end

-- function mod.XKeyCtrl(c)
--   return c | 0x20000000
-- end

-- function mod.XKeyAlt(c)
--   return c | 0x40000000
-- end

-- function mod.XKeySys(c)
--   return c | 0x80000000
-- end

-- do not change cb

local cb = {}

function cb.action(func)
  return cb.action_raw(function(ih)
    return func(ih) or const.default
  end)
end

function cb.getfocus_cb(func)
  return cb.getfocus_cb_raw(function(ih)
    return func(ih) or const.default
  end)
end

function cb.killfocus_cb(func)
  return cb.killfocus_cb_raw(function(ih)
    return func(ih) or const.default
  end)
end

function cb.k_any(func)
  return cb.k_any_raw(function(ih, c)
    return func(ih, c) or const.default
  end)
end

function cb.keypress_cb(func)
  return cb.keypress_cb_raw(function(ih, c, press)
    return func(ih, c, press) or const.default
  end)
end

function cb.help_cb(func)
  return cb.help_cb_raw(function(ih)
    return func(ih) or const.default
  end)
end

function cb.scroll_cb(func)
  return cb.scroll_cb_raw(function(ih, op, posx, posy)
    return func(ih, op, posx, posy) or const.default
  end)
end

function cb.resize_cb(func)
  return cb.resize_cb_raw(function(ih, width, height)
    return func(ih, width, height) or const.default
  end)
end

function cb.motion_cb(func)
  return cb.motion_cb_raw(function(ih, x, y, status)
    status = ffi.string(status)
    return func(ih, x, y, status) or const.default
  end)
end

function cb.button_cb(func)
  return cb.button_cb_raw(function(ih, button, pressed, x, y, status)
    status = ffi.string(status)
    return func(ih, button, pressed, x, y, status) or const.default
  end)
end

function cb.enterwindow_cb(func)
  return cb.enterwindow_cb_raw(function(ih)
    return func(ih) or const.default
  end)
end

function cb.leavewindow_cb(func)
  return cb.leavewindow_cb_raw(function(ih)
    return func(ih) or const.default
  end)
end

function cb.wheel_cb(func)
  return cb.wheel_cb_raw(function(ih, delta, x, y, status)
    status = ffi.string(status)
    return func(ih, delta, x, y, status) or const.default
  end)
end

function cb.open_cb(func)
  return cb.open_cb_raw(function(ih)
    return func(ih) or const.default
  end)
end

function cb.highlight_cb(func)
  return cb.highlight_cb_raw(function(ih)
    return func(ih) or const.default
  end)
end

function cb.menuclose_cb(func)
  return cb.menuclose_cb_raw(function(ih)
    return func(ih) or const.default
  end)
end

function cb.map_cb(func)
  return cb.map_cb_raw(function(ih)
    return func(ih) or const.default
  end)
end

function cb.unmap_cb(func)
  return cb.unmap_cb_raw(function(ih)
    return func(ih) or const.default
  end)
end

function cb.close_cb(func)
  return cb.close_cb_raw(function(ih)
    return func(ih) or const.default
  end)
end

function cb.show_cb(func)
  return cb.show_cb_raw(function(ih, state)
    return func(ih, state) or const.default
  end)
end

function cb.dropfiles_cb(func)
  return cb.dropfiles_cb_raw(function(ih, filename, num, x, y)
    filename = ffi.string(filename)
    return func(ih, filename, num, x, y) or const.default
  end)
end

function cb.wom_cb(func)
  return cb.wom_cb_raw(function(ih, state)
    return func(ih, state) or const.default
  end)
end

function cb.caret_cb(func)
  return cb.caret_cb_raw(function(ih, lin, col, pos)
    return func(ih, lin, col, pos) or const.default
  end)
end

cb.action_raw = 'int (*)(Ihandle*)'
cb.getfocus_cb_raw = 'int (*)(Ihandle*)'
cb.killfocus_cb_raw = 'int (*)(Ihandle*)'
cb.k_any_raw = 'int (*)(Ihandle*,int)'
cb.keypress_cb_raw = 'int (*)(Ihandle*,int,int)'
cb.help_cb_raw = 'int (*)(Ihandle*)'

cb.scroll_cb_raw = 'int (*)(Ihandle*,int,float,float)'
cb.resize_cb_raw = 'int (*)(Ihandle*,int,int)'
cb.motion_cb_raw = 'int (*)(Ihandle*,int,int,char*)'
cb.button_cb_raw = 'int (*)(Ihandle*,int,int,int,int,char*)'
cb.enterwindow_cb_raw = 'int (*)(Ihandle*)'
cb.leavewindow_cb_raw = 'int (*)(Ihandle*)'
cb.wheel_cb_raw = 'int (*)(Ihandle*,float,int,int,char*)'

cb.open_cb_raw = 'int (*)(Ihandle*)'
cb.highlight_cb_raw = 'int (*)(Ihandle*)'
cb.menuclose_cb_raw = 'int (*)(Ihandle*)'

cb.map_cb_raw = 'int (*)(Ihandle*)'
cb.unmap_cb_raw = 'int (*)(Ihandle*)'
cb.close_cb_raw = 'int (*)(Ihandle*)'
cb.show_cb_raw = 'int (*)(Ihandle*,int)'

cb.dropfiles_cb_raw = 'int (*)(Ihandle*,const char*,int,int,int)'
cb.wom_cb_raw = 'int (*)(Ihandle*,int)'
cb.caret_cb_raw = 'int (*)(Ihandle*,int,int,int)'

local builder_mt = {}

function builder_mt:__index(name)
  return function(t)
    local ih = mod.Create(name)
    help.set_attributes_lua(ih, t)
    return ih
  end
end

local builder = setmetatable({}, builder_mt)

function builder.image(t)
  local ih = mod.image(t.width, t.height, t.pixels)
  help.set_attributes_lua(ih, t)
  return ih
end

function builder.imagergb(t)
  local ih = mod.imagergb(t.width, t.height, t.pixels)
  help.set_attributes_lua(ih, t)
  return ih
end

function builder.imagergba(t)
  local ih = mod.imagergba(t.width, t.height, t.pixels)
  help.set_attributes_lua(ih, t)
  return ih
end

function help.vararg(...)
  local t = { ... }
  -- define the end of the list
  t[#t + 1] = 0
  ---@diagnostic disable-next-line: deprecated
  return unpack(t)
end

function help.vararr(ctype, array)
  if type(array) == 'table' then
    local vtype = ffi.typeof('$[?]', ffi.typeof(ctype))
    local vsize = #array + 1

    array = ffi.new(vtype, vsize, array)
    -- define the end of the list
    array[vsize - 1] = nil
  end

  return array
end

function help.attrname(name)
  return type(name) == 'string' and name:upper() or name
end

function help.attrvalue(value)
  return type(value) ~= 'cdata' and tostring(value) or value
end

function help.set_attribute_lua(handle, index, value)
  local ti = type(index)
  local tv = type(value)

  if ti == 'number' or ti == 'string' then
    local index_lo = string.lower(index)
    local index_up = string.upper(index)

    local cbtype = cb[index_lo]
    if cbtype then
      if type(value) == 'function' then
        value = cbtype(value)
      end
      mod.SetCallback(handle, index_up, value)
    elseif ffi.istype('Ihandle', value) then
      mod.SetAttributeHandle(handle, index, value)
    elseif tv == 'string' or tv == 'number' or tv == 'nil' then
      mod.SetAttribute(handle, index_up, value)
    end
  end
end

function help.set_attributes_lua(ih, t)
  if not ih or not t then
    return
  end

  local i = 1
  for k, v in pairs(t) do
    if k == i then
      i = i + 1
      if v then -- Add null check
        mod.Append(ih, v)
      end
    else
      help.set_attribute_lua(ih, k, v)
    end
  end
end

function help.strchar(s, i)
  if not s then
    return nil
  end

  if type(s) == 'string' then
    return string.sub(s, i + 1, i + 1)
  end
  return string.char(s[i])
end

local widget_mt = {}
widget_mt.__index = widget_mt

widget_mt.__newindex = help.set_attribute_lua

widget_mt.Update = mod.Update
widget_mt.UpdateChildren = mod.UpdateChildren
widget_mt.Redraw = mod.Redraw
widget_mt.Refresh = mod.Refresh
widget_mt.RefreshChildren = mod.RefreshChildren

widget_mt.Append = mod.Append
widget_mt.Insert = mod.Insert
widget_mt.GetChild = mod.GetChild
widget_mt.GetChildPos = mod.GetChildPos
widget_mt.GetChildCount = mod.GetChildCount
widget_mt.GetNextChild = mod.GetNextChild
widget_mt.GetBrother = mod.GetBrother
widget_mt.GetParent = mod.GetParent
widget_mt.GetDialog = mod.GetDialog
widget_mt.GetDialogChild = mod.GetDialogChild

widget_mt.Popup = mod.Popup
widget_mt.Show = mod.Show
widget_mt.ShowXY = mod.ShowXY
widget_mt.Hide = mod.Hide
widget_mt.Map = mod.Map
widget_mt.Unmap = mod.Unmap

widget_mt.ResetAttribute = mod.ResetAttribute
widget_mt.GetAllAttributes = mod.GetAllAttributes
widget_mt.SetAttributes = mod.SetAttributes
widget_mt.GetAttributes = mod.GetAttributes
widget_mt.SetAttribute = mod.SetAttribute
widget_mt.SetStrAttribute = mod.SetStrAttribute
widget_mt.SetAttribute = mod.SetAttribute
widget_mt.SetInt = mod.SetInt
widget_mt.SetFloat = mod.SetFloat
widget_mt.SetDouble = mod.SetDouble
widget_mt.SetRGB = mod.SetRGB
widget_mt.GetAttribute = mod.GetAttribute
widget_mt.GetInt = mod.GetInt
widget_mt.GetInt2 = mod.GetInt2
widget_mt.GetIntInt = mod.GetIntInt
widget_mt.GetFloat = mod.GetFloat
widget_mt.GetDouble = mod.GetDouble
widget_mt.GetRGB = mod.GetRGB
widget_mt.SetAttributeId = mod.SetAttributeId
widget_mt.SetStrAttributeId = mod.SetStrAttributeId
widget_mt.SetAttributeId = mod.SetAttributeId
widget_mt.SetIntId = mod.SetIntId
widget_mt.SetFloatId = mod.SetFloatId
widget_mt.SetDoubleId = mod.SetDoubleId
widget_mt.SetRGBId = mod.SetRGBId
widget_mt.GetAttributeId = mod.GetAttributeId
widget_mt.GetIntId = mod.GetIntId
widget_mt.GetFloatId = mod.GetFloatId
widget_mt.GetDoubleId = mod.GetDoubleId
widget_mt.GetRGBId = mod.GetRGBId
widget_mt.SetAttributeId2 = mod.SetAttributeId2
widget_mt.SetStrAttributeId2 = mod.SetStrAttributeId2
widget_mt.SetStrfId2 = mod.SetStrfId2
widget_mt.SetIntId2 = mod.SetIntId2
widget_mt.SetFloatId2 = mod.SetFloatId2
widget_mt.SetDoubleId2 = mod.SetDoubleId2
widget_mt.SetRGBId2 = mod.SetRGBId2
widget_mt.GetAttributeId2 = mod.GetAttributeId2
widget_mt.GetIntId2 = mod.GetIntId2
widget_mt.GetFloatId2 = mod.GetFloatId2
widget_mt.GetDoubleId2 = mod.GetDoubleId2
widget_mt.GetRGBId2 = mod.GetRGBId2

widget_mt.PreviousField = mod.PreviousField
widget_mt.NextField = mod.NextField
widget_mt.GetCallback = mod.GetCallback
widget_mt.SetCallback = mod.SetCallback
widget_mt.SetCallbacks = mod.SetCallbacks

widget_mt.GetName = mod.GetName
widget_mt.SetAttributeHandle = mod.SetAttributeHandle
widget_mt.GetAttributeHandle = mod.GetAttributeHandle
widget_mt.GetClassName = mod.GetClassName
widget_mt.GetClassType = mod.GetClassType

mod.raw = bind

mod.const = const

mod.cb = cb

mod.builder = builder

setmetatable(mod, {
  __index = const, -- fallback lookup for constants (e.g. mod.ERROR)

  __call = function(self, name)
    ffi.cdef(header)
    bind = ffi.load(name)
    ffi.metatype('Ihandle', widget_mt)

    for k, v in pairs(cb) do
      cb[k] = type(v) == 'string' and ffi.typeof(v) or v
    end

    return self
  end
})

return mod("iup")
