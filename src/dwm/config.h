/* See LICENSE file for copyright and license details. */

#include <X11/XF86keysym.h>

/* appearance */
static const unsigned int borderpx  = 1;        /* border pixel of windows */
static const unsigned int fborderpx = 3;        /* border pixel of focused window */
static const unsigned int gappx     = 10;       /* gaps between windows */
static const unsigned int snap      = 32;       /* snap pixel */
static const int showbar            = 1;        /* 0 means no bar */
static int topbar             = 1;        /* 0 means bottom bar */
static const char *fonts[]          = { 
	"JetBrainsMono Nerd font Mono:size=11",
	"NotoColorEmoji:pixelsize=10:antialias=true:autohint=true"
};
static const char dmenufont[]       = "DejaVuSansM Nerd font Mono:size=12";
static const char col_gray1[]       = "#0d0d12";
static const char col_gray2[]       = "#4d2735";
static const char col_gray3[]       = "#e8eaf0";
static const char col_gray4[]       = "#e8eaf0";
static const char col_cyan[]        = "#ff4fc3";
static const char col_accent[]      = "#b8567f";
static const char *colors[][3]      = {
	/*               fg         bg         border   */
	[SchemeNorm] = { col_gray3, col_gray1, col_gray2 },
	[SchemeSel]  = { col_gray4, col_accent,  col_accent  },
};

/* tagging */
static const char *tags[] = { "1", "2", "3", "4", "5", "6", "7", "8", "9" };

static const Rule rules[] = {
	/* xprop(1):
	 *	WM_CLASS(STRING) = instance, class
	 *	WM_NAME(STRING) = title
	 */
	/* class      instance    title       tags mask     isfloating   monitor */
	{ "Gimp",     NULL,       NULL,       0,            1,           -1 },
	{ "Firefox",  NULL,       NULL,       1 << 8,       0,           -1 },
        { "mpv",     NULL,      "webcam-preview",       0,            1,           -1 },
        { NULL,      "masterterm",      NULL,		0, 	      1,           -1 },
};

/* layout(s) */
static const float mfact     = 0.55; /* factor of master area size [0.05..0.95] */
static const int nmaster     = 1;    /* number of clients in master area */
static const int resizehints = 1;    /* 1 means respect size hints in tiled resizals */
static const int lockfullscreen = 1; /* 1 will force focus on the fullscreen window */
static const int refreshrate = 120;  /* refresh rate (per second) for client move/resize */

static const Layout layouts[] = {
	/* symbol     arrange function */
	{ "[]=",      tile },    /* first entry is default */
	{ "><>",      NULL },    /* no layout function means floating behavior */
	{ "[M]",      monocle },
    { "|M|",      centeredmaster },
};

/* key definitions */
#define MODKEY Mod1Mask
#define TAGKEYS(KEY,TAG) \
	{ MODKEY,                       KEY,      view,           {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask,           KEY,      toggleview,     {.ui = 1 << TAG} }, \
	{ MODKEY|ShiftMask,             KEY,      tag,            {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask|ShiftMask, KEY,      toggletag,      {.ui = 1 << TAG} },

/* helper for spawning shell commands in the pre dwm-5.0 fashion */
#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }
#define STATUSBAR "dwmblocks"

/* commands */
static char dmenumon[2] = "0"; /* component of dmenucmd, manipulated in spawn() */
static const char *dmenucmd[] = { "dmenu_run", "-m", dmenumon, "-fn", dmenufont, "-nb", col_gray1, "-nf", col_gray3, "-sb", col_accent, "-sf", col_gray3, NULL };
static const char *termcmd[]  = { "st", NULL };

static const char *scratchcmd[] = { "st", "-n", "masterterm", NULL };

static const Key keys[] = {
	/* modifier                     key        function        argument */
	{ MODKEY,                       XK_p,      spawn,          SHCMD("rofi -show drun -theme ~/.config/rofi/launcher.rasi") },
	{ MODKEY,             XK_Return, spawn,          {.v = termcmd } },
	{ MODKEY,                       XK_b,      togglebar,      {0} },
	{ MODKEY,                       XK_j,      focusstack,     {.i = +1 } },
	{ MODKEY,                       XK_k,      focusstack,     {.i = -1 } },
	{ MODKEY,                       XK_i,      incnmaster,     {.i = +1 } },
	{ MODKEY,                       XK_d,      incnmaster,     {.i = -1 } },
	{ MODKEY,                       XK_h,      setmfact,       {.f = -0.05} },
	{ MODKEY,                       XK_l,      setmfact,       {.f = +0.05} },
	{ MODKEY,                       XK_z,	   zoom,           {0} },
	{ MODKEY|ShiftMask,             XK_Return, togglescratch,  {0} },
	{ MODKEY,                       XK_Tab,    focusstack,     {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_c,      killclient,     {0} },
	{ MODKEY,                       XK_t,      setlayout,      {.v = &layouts[0]} },
	{ MODKEY,                       XK_f,      setlayout,      {.v = &layouts[1]} },
	{ MODKEY|ShiftMask,		XK_f,	   togglefullscr,  {0} },
	{ MODKEY,                       XK_m,      setlayout,      {.v = &layouts[2]} },
	{ MODKEY,                       XK_space,  setlayout,      {0} },
	{ MODKEY|ShiftMask,             XK_space,  togglefloating, {0} },
	{ MODKEY,                       XK_0,      view,           {.ui = ~0 } },
	{ MODKEY|ShiftMask,             XK_0,      tag,            {.ui = ~0 } },
	{ MODKEY,                       XK_comma,  focusmon,       {.i = -1 } },
	{ MODKEY,                       XK_period, focusmon,       {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_comma,  tagmon,         {.i = -1 } },
	{ MODKEY|ShiftMask,             XK_period, tagmon,         {.i = +1 } },
	{ 0, 				XK_Print,  spawn,	   SHCMD("screenshot") },
	{ ShiftMask,			XK_Print,  spawn,	   SHCMD("screenshot area") },
	{ 0, XF86XK_AudioRaiseVolume, spawn, SHCMD("pamixer --allow-boost -i 5; pkill -RTMIN+10 dwmblocks") },
	{ 0, XF86XK_AudioLowerVolume, spawn, SHCMD("pamixer --allow-boost -d 5; pkill -RTMIN+10 dwmblocks") },
	{ 0, XF86XK_AudioMute, spawn, SHCMD("pamixer -t; pkill -RTMIN+10 dwmblocks") },
	{ 0, XF86XK_AudioMicMute, spawn, SHCMD("pamixer --default-source -t") },
	{ 0, XF86XK_MonBrightnessUp, spawn, SHCMD("brightnessctl set +10%") },
	{ 0, XF86XK_MonBrightnessDown, spawn, SHCMD("brightnessctl set 10%-") },
	{ 0, XF86XK_AudioPlay, spawn, SHCMD("mpc toggle") },
	{ 0, XF86XK_AudioNext, spawn, SHCMD("mpc next") },
	{ 0, XF86XK_AudioPrev, spawn, SHCMD("mpc prev") },
	{ Mod4Mask, XK_l, spawn, SHCMD("slock") },
        { Mod4Mask,			XK_F2,     spawn,          SHCMD("dotfiles-menu") },
	{ Mod4Mask, 			XK_F1,     spawn, 	   SHCMD("zathura ~/Documents/Navi-Keybinds.pdf") },	
	{ Mod4Mask,			XK_F3,	   spawn,          SHCMD("file-search") },
        { Mod4Mask,			XK_F4,	   spawn,	   SHCMD("display-switch") },
	{ Mod4Mask,			XK_F5,	   spawn,	   SHCMD("usb-mount") },
	{ Mod4Mask,			XK_F6,	   spawn,	   SHCMD("usb-unmount") },
	{ Mod4Mask,			XK_F9,	   spawn,	   SHCMD("record-toggle audio") },
	{ Mod4Mask,			XK_F10,	   spawn,	   SHCMD("record-toggle screen") },
	{ Mod4Mask|ShiftMask,		XK_F10,    spawn,          SHCMD("record-toggle webcam") },
	{ Mod4Mask,			XK_F11,    spawn,	   SHCMD("webcam-toggle") },
	{ Mod4Mask|ShiftMask,		XK_F11,    spawn,	   SHCMD("webcam-toggle tile") },
	{ Mod4Mask,			XK_e,      spawn,          SHCMD("st -e neomutt") },
	{ Mod4Mask,                     XK_m,      spawn,          SHCMD("st -e ncmpcppv") },
	{ Mod4Mask,			XK_c,	   spawn,          SHCMD("st -e nvim") },
	{ Mod4Mask,			XK_i,	   spawn,	   SHCMD("librewolf") },
	{ Mod4Mask, 			XK_f,      spawn,          SHCMD("st -e lfv") },
	{ Mod4Mask,			XK_s,	   spawn,	   SHCMD("st -e htop") },
	{ Mod4Mask,			XK_a, 	   spawn,	   SHCMD("st -e qalc") },
	{ Mod4Mask,			XK_u,	   spawn,	   SHCMD("st -e navi-update") },
	{ Mod4Mask,			XK_n,	   spawn,          SHCMD("st -e nmtui") },
	{ Mod4Mask,			XK_r,	   spawn,	   SHCMD("st -e newsboat") },
	{ Mod4Mask,			XK_p,	   spawn,	   SHCMD("rofi -show drun -theme ~/.config/rofi/launcher.rasi") },
	{ Mod4Mask|ShiftMask,		XK_p,	   spawn,	   SHCMD("system-config-printer") },
        { Mod4Mask,                     XK_Return, spawn,          {.v = termcmd } },
        { Mod4Mask|ShiftMask,           XK_Return, togglescratch,  {0} },
	TAGKEYS(                        XK_1,                      0)
	TAGKEYS(                        XK_2,                      1)
	TAGKEYS(                        XK_3,                      2)
	TAGKEYS(                        XK_4,                      3)
	TAGKEYS(                        XK_5,                      4)
	TAGKEYS(                        XK_6,                      5)
	TAGKEYS(                        XK_7,                      6)
	TAGKEYS(                        XK_8,                      7)
	TAGKEYS(                        XK_9,                      8)
   { Mod4Mask|ShiftMask,           XK_backslash, togglebarpos,   {0} },
	{ MODKEY|ShiftMask,             XK_q,      spawn,          SHCMD("confirm-logout") },
};

/* button definitions */
/* click can be ClkTagBar, ClkLtSymbol, ClkStatusText, ClkWinTitle, ClkClientWin, or ClkRootWin */
static const Button buttons[] = {
	/* click                event mask      button          function        argument */
	{ ClkLtSymbol,          0,              Button1,        setlayout,      {0} },
	{ ClkLtSymbol,          0,              Button3,        setlayout,      {.v = &layouts[2]} },
	{ ClkWinTitle,          0,              Button2,        zoom,           {0} },
	{ ClkStatusText,        0,              Button1,        sigstatusbar,   {.i = 1} },
        { ClkStatusText,        0,              Button2,        sigstatusbar,   {.i = 2} },
        { ClkStatusText,        0,              Button3,        sigstatusbar,   {.i = 3} },
        { ClkStatusText,        0,              Button4,        sigstatusbar,   {.i = 4} },
        { ClkStatusText,        0,              Button5,        sigstatusbar,   {.i = 5} },
        { ClkStatusText,        0,              6,              sigstatusbar,   {.i = 6} },
        { ClkStatusText,        0,              7,              sigstatusbar,   {.i = 7} },
        { ClkStatusText,        0,              8,              sigstatusbar,   {.i = 8} },
        { ClkStatusText,        0,              9,              sigstatusbar,   {.i = 9} },
	{ ClkClientWin,         MODKEY,         Button1,        movemouse,      {0} },
	{ ClkClientWin,         MODKEY,         Button2,        togglefloating, {0} },
	{ ClkClientWin,         MODKEY,         Button3,        resizemouse,    {0} },
	{ ClkTagBar,            0,              Button1,        view,           {0} },
	{ ClkTagBar,            0,              Button3,        toggleview,     {0} },
	{ ClkTagBar,            MODKEY,         Button1,        tag,            {0} },
	{ ClkTagBar,            MODKEY,         Button3,        toggletag,      {0} },
};

