#include <Timer.h>
#include <printf.h>

#define AM_BLINKTORADIO 6

configuration sbAppC {
}

implementation {
	components MainC;
	components LedsC;
	components sbC;
	components ActiveMessageC;
	components RandomC;
	components PrintfC;
	components SerialStartC;
	components new AMSenderC(AM_BLINKTORADIO);
	components new AMReceiverC(AM_BLINKTORADIO);
	components new TimerMilliC() as Timer_init;
	components new TimerMilliC() as Timer_scan;
	components new TimerMilliC() as Timer_dead;
	components new TimerMilliC() as Timer_startgame;
	components new TimerMilliC() as Timer_winner;
	components new TimerMilliC() as Timer_fight;
	components new TimerMilliC() as Timer_attack;
	components new TimerMilliC() as Timer_attacked;
	components new HamamatsuS1087ParC();   

	sbC -> MainC.Boot;

	sbC.Boot -> MainC;
	sbC.Leds -> LedsC;
	sbC.Random -> RandomC;
	sbC.AMControl -> ActiveMessageC;
	sbC.Packet -> AMSenderC;
	sbC.AMPacket -> AMSenderC;
	sbC.AMSend -> AMSenderC;
	sbC.Receive -> AMReceiverC;
	sbC.Timer_init -> Timer_init;
	sbC.Timer_scan -> Timer_scan;
	sbC.Timer_dead -> Timer_dead;
	sbC.Timer_winner -> Timer_winner;
	sbC.Timer_startgame -> Timer_startgame;
	sbC.Timer_fight -> Timer_fight;
	sbC.Timer_attack -> Timer_attack;
	sbC.Timer_attacked -> Timer_attacked;
	sbC.Read -> HamamatsuS1087ParC;
}
