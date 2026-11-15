/* user and group to drop privileges to */
static const char *user  = "nobody";
static const char *group = "nobody";

static const char *colorname[NUMCOLS] = {
	[INIT] =   "black",     /* after initialization */
	[INPUT] =  "#b8567f",   /* during input */
	[FAILED] = "#CC3333",   /* wrong password */
};

/* treat a cleared input like a wrong password (color) */
static const int failonclear = 1;

/* default message */
static const char * message = "Enter password:";

/* text color */
static const char * text_color = "#e8eaf0";

/* text size (must be a valid size) */
static const char * font_name = "-xos4-terminus-bold-r-normal--28-280-72-72-c-140-iso10646-1";
