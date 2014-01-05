#include "protocol.h"
#include <printf.h>
#include <math.h>

module sbC @safe()
{
	uses interface Timer<TMilli> as Timer_init;
	uses interface Timer<TMilli> as Timer_scan;
	uses interface Timer<TMilli> as Timer_dead;
	uses interface Timer<TMilli> as Timer_winner;
	uses interface Timer<TMilli> as Timer_startgame;
	uses interface Timer<TMilli> as Timer_fight;
	uses interface Timer<TMilli> as Timer_attack;
	uses interface Timer<TMilli> as Timer_attacked;
	uses interface SplitControl as AMControl;
	uses interface AMSend;
	uses interface AMPacket;
	uses interface Packet;
	uses interface Receive;
	uses interface Boot;
	uses interface Leds;
	uses interface Random;
	uses interface Read<uint16_t>;
}

implementation 
{
	int8_t inited = 0;
	int8_t fscan = 0;
	int8_t fattack = 0;
	int8_t fattacked = 0;
	int8_t fstartgame = 0;
	int8_t fwinner = 0;
	int8_t life = 300;
	int8_t atk = 0;
	bool started = FALSE;
	bool gamestarted = FALSE;
	bool busy = FALSE;
	void m_init();
	void m_scan();
	void m_attacked(int8_t);
	void startgame(bool f);


	uint16_t counter;
	message_t pkt;

	event void Boot.booted()
	{
		//节点启动
		printf("booted!\n");
		m_init();
	}

	event void AMSend.sendDone(message_t *msg, error_t error)
	{
		//发送数据的回调
		if (error == SUCCESS)
		{
			
		}
		else
		{
			//Timer_scan.stop();
		}
	}

	event message_t *Receive.receive(message_t *msg, void *payload, uint8_t len)
	{
		//接收数据的回调
		pPPackage rpkg;
		/*return msg;
		if (!busy)
		{
			call Timer_winner.startPeriodic(250);
			busy = TRUE;
		}*/
		if (!started)
		{
			//游戏未启动时屏蔽所有的包
			return msg;
		}
		if (len != sizeof(PPackage))
		{
			//屏蔽大小不一致的包
			return msg;
		}
		rpkg = (pPPackage)payload;
		if (rpkg->action == ACTION_FIND || rpkg->action == ACTION_START_GAME)
		{
			//玩家搜索到或者被搜索到
			if (gamestarted)
			{
				return msg;
			}
			startgame(rpkg->action == ACTION_FIND ? TRUE : FALSE);
			return msg;
			//AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(1));
		}
		else if (rpkg->action == ACTION_ATTACK)
		{
			//战斗数据
			m_attacked((int8_t)rpkg->data);
			return msg;	
		}
		else if (rpkg->action == ACTION_DIE)
		{
			//对方死亡
			call Timer_fight.stop();
			call Timer_winner.startPeriodic(250);
			printf("game over! you are winner! congratulations!");
			return msg;
		}
		if (!busy)
		{
			call Timer_winner.startPeriodic(250);
			busy = TRUE;
		}
		return msg;
	}

	void startgame(bool f)
	{
		//搜索到玩家后启动游戏
		pPPackage spkg;
		if (f)
		{
			//被搜索到则还要返回一个包告知
			spkg = (pPPackage)call Packet.getPayload(&pkt, sizeof(PPackage));
			spkg->action = ACTION_START_GAME;
			call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(PPackage));
		}
		gamestarted = TRUE;
		call Timer_scan.stop();
		call Leds.led0Off();
		call Leds.led1Off();
		call Leds.led2Off();
		call Timer_startgame.startPeriodic(100);
		printf("going to fight");
	}

	event void AMControl.startDone(error_t err)
	{
		//split操作回调
		if (err == SUCCESS)
		{
			call Timer_init.startPeriodic(1000);
			//call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(1));
		}
		else
		{
			//call Leds.led2Toggle();
			call AMControl.start();
		}
	}


	event void AMControl.stopDone(error_t err)
	{
	}


	void m_init()
	{
		inited = 0;
		fscan = 0;
		busy = FALSE;
		started = FALSE;
		call AMControl.start();
	}

	void m_scan()
	{
		//开始扫描玩家
		call Timer_init.stop();
		//call Leds.led2Toggle();
		call Timer_scan.startPeriodic(100);
		started = TRUE;
	}

	event void Timer_init.fired()
	{
		//启动时闪灯
		inited = inited + 1;
		if (inited == 5)
		{
			return;
		}
		else if (inited == 6)
		{
			m_scan();
			return;
		}
		call Leds.led0Toggle();
		call Leds.led1Toggle();
		call Leds.led2Toggle();
	}

	event void Timer_scan.fired()
	{
		//扫描时闪灯
		pPPackage spkg;
		printf("scanning...\n");
		fscan = fscan % 7;
		if (fscan == 0)
		{
			call Leds.led0Toggle();
		}
		else if (fscan == 1)
		{
			call Leds.led1Toggle();
			call Leds.led0Toggle();
		}
		else if (fscan == 2)
		{
			call Leds.led2Toggle();
			call Leds.led1Toggle();
		}
		else if (fscan == 3)
		{
			call Leds.led2Toggle();
		}
		//else if (fscan == 4)
		//{
		
		//发搜索包
		spkg = (pPPackage)call Packet.getPayload(&pkt, sizeof(PPackage));
		spkg->action = ACTION_FIND;
		call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(PPackage));
			//if (spkg == 0)
			//{
			//	call Timer_scan.stop();
			//}
		//}
		fscan = fscan + 1;
		
		/*
		counter++;
		if (!busy) 
		{
			BlinkToRadioMsg* btrpkt = (BlinkToRadioMsg*)(call Packet.getPayload(&pkt, sizeof(BlinkToRadioMsg)));
			if (btrpkt == NULL) 
			{
				return;
			}
			btrpkt->nodeid = TOS_NODE_ID;
			btrpkt->counter = counter;
			if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(BlinkToRadioMsg)) == SUCCESS) 
			{
				busy = TRUE;
			}
		}*/
	}

	event void Timer_startgame.fired()
	{
		//游戏启动
		if (fstartgame == 11)
		{
			call Timer_startgame.stop();
			call Timer_fight.startPeriodic(2000 + (call Random.rand16() % 4000));
		}
		call Leds.led0Toggle();
		call Leds.led1Toggle();
		call Leds.led2Toggle();
		fstartgame = fstartgame + 1;
	}
	
	event void Timer_fight.fired()
	{
		//战斗
		//每一回合调用一次
		pPPackage spkg;
		call Read.read();
		call Timer_attack.startPeriodic(300);
		spkg = (pPPackage)call Packet.getPayload(&pkt, sizeof(PPackage));
		spkg->action = ACTION_ATTACK;
		spkg->data = (nx_uint8_t)atk;
		call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(PPackage));
		call Timer_fight.stop();
		call Timer_fight.startPeriodic(2000 + (call Random.rand16() % 4000));
		printf("attacking! ==> %i\n", atk);
	}

	event void Timer_dead.fired()
	{
		//死亡时闪灯
		call Leds.led0On();
		call Leds.led1On();
		call Leds.led2On();
	}

	void m_attacked(int8_t x)
	{
		//被攻击时的回调
		//参数x为对方攻击的力量
		pPPackage spkg;
		call Timer_attacked.startPeriodic(300);
		life = life - x;
		if (life < 0)
		{
			//当生命力低于0时，即死亡
			spkg = (pPPackage)(call Packet.getPayload(&pkt, sizeof(PPackage)));
			spkg->action = ACTION_DIE;
			call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(PPackage));
			call Timer_fight.stop();
			call Timer_dead.startPeriodic(100);
			printf("game over! you lose !\n");
			return;
		}
		printf("be attacked!  life : %i , -%i\n", life, x);
		return;
	}
	
	event void Timer_attack.fired()
	{
		//攻击对方闪灯
		if (fattack++ & 1)
		{
			call Timer_attack.stop();
		}
		call Leds.led0Toggle();
	}
	
	event void Timer_attacked.fired()
	{
		//被攻击时闪灯
		if (fattacked & 1)
		{
			call Leds.led2Off();
		}
		else
		{
			call Leds.led2On();
		}
		if (fattacked % 4 == 3)
		{
			call Timer_attacked.stop();
		}
		fattacked = fattacked + 1;
	}
	
	event void Timer_winner.fired()
	{
		//战斗胜利者闪灯
		if (fwinner++ & 1)
		{
			call Leds.led0On();
			call Leds.led1On();
			call Leds.led2On();
		}
		else
		{
			call Leds.led0Off();
			call Leds.led1Off();
			call Leds.led2Off();
		}
	}

	
	event void Read.readDone(error_t result, uint16_t data) 
	{
		if (result == SUCCESS)
		{
			atk = sqrt(sqrt(data * 10) * 10);
			//光照强度转化为节电攻击力。保证了光照强度的稳定性。
		}
	}
}
