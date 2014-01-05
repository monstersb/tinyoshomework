#define ACTION_FIND		0x00
#define ACTION_START_GAME	0x01
#define ACTION_ATTACK		0x02
#define ACTION_DIE		0x03

typedef nx_struct{
	nx_uint8_t action;
	nx_uint8_t data;
} PPackage, *pPPackage;
