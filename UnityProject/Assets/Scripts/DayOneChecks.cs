using System;

namespace Sunflower
{
    // Pure C# checks shared by the Unity menu and standalone console runner.
    public static class DayOneChecks
    {
        static void Require(bool value,string message){if(!value)throw new Exception(message);}
        static TavernModel FirstGuest()
        {
            var model=new TavernModel{started=true};model.Update(8.1f);
            Require(model.visitors.Count==1,"First visitor did not arrive");return model;
        }
        static TavernModel SnowyVisit(bool assisted=false)
        {
            var day=new DayConfiguration(60,10,new[]{DayConfiguration.CreateSnowy()},new[]{new ArrivalDefinition(1,0,3)});
            var model=new TavernModel(day,assisted){started=true};model.Update(1.1f);return model;
        }
        static void CheckSnowy()
        {
            foreach(bool assisted in new[]{false,true})
            {
                var model=SnowyVisit(assisted);var guest=model.At(3);
                Require(guest.NeedsCooling&&guest.heatLimit==(assisted?18:12),"Snowy heat budget incorrect");
                float heat=guest.heatRemaining;model.direction=3;model.Update(1);
                Require(Math.Abs(heat-guest.heatRemaining-1)<.01f,"Facing Snowy extended heat budget");
                heat=guest.heatRemaining;model.paused=true;model.Interact();model.Update(20);
                Require(guest.heatRemaining==heat&&guest.state==VisitState.Order&&model.queue.Count==0,"Paused Snowy advanced");model.paused=false;
                model.Interact();Require(guest.heatRemaining==heat,"Accepting Snowy reset heat");
                model.Update(3.1f);model.direction=0;model.Interact();model.direction=3;model.Interact();
                heat=guest.heatRemaining;Require(!guest.NeedsCooling&&guest.state==VisitState.Drinking&&!model.codex.Contains("snowy"),"Cooling settled early");
                model.Update(2.1f);Require(guest.heatRemaining==heat&&guest.state==VisitState.Payment,"Heat continued after delivery");
                model.Interact();int coins=model.coins;model.Interact();
                Require(model.served==1&&coins==13&&model.coins==coins&&model.codex.Contains("snowy"),"Snowy settlement/codex invalid");
            }
            foreach(int phase in new[]{0,1,2,3})
            {
                var model=SnowyVisit();var guest=model.At(3);model.coins=8;model.combo=2;model.direction=3;
                if(phase>0){model.Interact();if(phase==1)model.brewSpeed=.01f;}
                if(phase>=2)model.Update(3.1f);
                if(phase==3){model.direction=0;model.Interact();}
                guest.heatRemaining=.01f;model.Update(.1f);model.Interact();
                Require(model.visitors.Count==0&&model.queue.Count==0&&model.ready==null&&model.hand==null&&model.coins==8&&model.missed==1&&model.combo==0&&!model.codex.Contains("snowy"),"Snowy expiry left order or changed earnings");
            }
            var normal=SnowyVisit();normal.direction=3;normal.Update(12);
            var assist=SnowyVisit(true);assist.direction=3;assist.Update(12);
            Require(normal.missed==1&&assist.visitors.Count==1,"Assist heat window not longer");assist.Update(6);Require(assist.missed==1,"Assist Snowy never left");
            var warning=SnowyVisit();warning.Update(7.2f);int target;
            Require(warning.At(3).HeatWarning&&warning.ServiceHint(out target).Contains("Snowy")&&target==3,"Heat warning/guide missing");
            var ended=SnowyVisit();float frozen=ended.At(3).heatRemaining;ended.ended=true;ended.Update(30);
            Require(ended.At(3).heatRemaining==frozen,"Heat advanced after end");
            var wrong=SnowyVisit();wrong.direction=3;wrong.Interact();wrong.hand=new Cup{owner=99,drink="芒果冰沙"};float before=wrong.At(3).heatRemaining;wrong.Interact();
            Require(wrong.At(3).NeedsCooling&&wrong.At(3).heatRemaining==before&&wrong.hand!=null,"Wrong cup cooled Snowy");
        }
        static TavernModel SpfOrder()
        {
            var model=new TavernModel(new DayConfiguration(60,10,new[]{DayConfiguration.CreateSpf8()},new[]{new ArrivalDefinition(1,0,3)})){started=true};
            model.Update(1.1f);model.direction=3;model.Interact();return model;
        }
        static void CheckSpf8()
        {
            var model=SpfOrder();var guest=model.At(3);model.Interact();
            Require(model.queue.Count==2&&model.queue.TrueForAll(c=>c.owner==guest.id),"SPF duplicate or wrong-owner cups");
            model.Update(5.1f);model.direction=0;model.Interact();model.direction=3;
            float patience=guest.patience;model.Interact();model.Interact();
            Require(guest.deliveredCups==1&&guest.state==VisitState.Waiting&&guest.patience==patience&&model.coins==0&&!model.codex.Contains("spf8"),"Partial SPF order settled or reset patience");
            var cup=model.queue[0];float remaining=cup.remaining;
            model.paused=true;model.Update(8);model.Interact();
            Require(cup.remaining==remaining&&guest.deliveredCups==1,"Paused SPF advanced");model.paused=false;
            model.Update(5.1f);model.direction=0;model.Interact();model.direction=3;model.Interact();model.Interact();
            Require(guest.deliveredCups==2&&guest.state==VisitState.Drinking&&model.hand==null,"SPF final cup invalid");
            model.Update(2.1f);model.Interact();int income=model.coins;model.Interact();
            Require(model.served==1&&model.combo==1&&income==28+guest.tip&&model.coins==income&&model.codex.Contains("spf8"),"SPF charged twice or incorrect price");
            foreach(int phase in new[]{0,1,2})
            {
                var expired=SpfOrder();var v=expired.At(3);
                expired.Update(5.1f);expired.direction=0;expired.Interact();expired.direction=3;expired.Interact();
                if(phase>0)expired.Update(5.1f);
                if(phase==2){expired.direction=0;expired.Interact();}
                v.patience=.001f;expired.Update(.1f);
                Require(expired.visitors.Count==0&&expired.queue.Count==0&&expired.ready==null&&expired.hand==null&&expired.missed==1&&expired.coins==0&&!expired.codex.Contains("spf8"),"Partial SPF timeout left cups/reward");
            }
            var wrong=SpfOrder();var target=wrong.At(3);wrong.hand=new Cup{owner=99,drink=target.guest.drink};wrong.Interact();
            Require(target.deliveredCups==0&&wrong.hand!=null&&target.patience<25,"Wrong cup advanced SPF progress");
            var source=DayConfiguration.CreateSpf8();var config=new DayConfiguration(60,10,new[]{source},new[]{new ArrivalDefinition(1,0,3)});source.cups=1;
            Require(config.Guests[0].cups==2,"Configuration lost or shared cup count");
            bool rejected=false;source.cups=3;try{new DayConfiguration(60,10,new[]{source},new[]{new ArrivalDefinition(1,0,3)});}catch(ArgumentException){rejected=true;}
            Require(rejected,"Invalid cup count accepted");
        }
        static TavernModel MimiOrder(bool assisted=false)
        {
            var day=new DayConfiguration(60,10,new[]{DayConfiguration.CreateMimi()},new[]{new ArrivalDefinition(1,0,3)});
            var model=new TavernModel(day,assisted){started=true,coins=10};
            model.Update(1.1f);model.direction=3;model.Interact();return model;
        }
        static void CheckMimi()
        {
            foreach(bool assisted in new[]{false,true})
            {
                var model=MimiOrder(assisted);var guest=model.At(3);
                model.Update(4);Require(!guest.MimiWarning&&guest.mimiAway==0,"Facing Mimi started warning");
                model.direction=0;model.Update(3.1f);
                Require(guest.MimiWarning&&model.coins==10,"Mimi warning missing or early theft");
                int target;Require(model.ServiceHint(out target).Contains("打断")&&target==3,"Mimi guidance missing");
                model.Interact();var cup=model.hand;Require(cup!=null,"Mimi test cup missing");
                float warning=guest.mimiWarningTime,patience=guest.patience;
                model.paused=true;model.direction=3;model.Interact();model.Update(10);
                Require(guest.MimiWarning&&guest.mimiWarningTime==warning&&guest.patience==patience&&model.coins==10,"Paused Mimi advanced");
                model.paused=false;model.Interact();
                Require(guest.mimiAttempted&&!guest.MimiWarning&&model.hand==cup&&guest.state==VisitState.Waiting&&guest.patience==patience,"Interrupt changed order/cup/patience");
                model.Interact();Require(model.hand==null&&guest.state==VisitState.Drinking,"Second interaction did not deliver");
                model.Update(2.1f);model.Interact();model.Interact();
                Require(model.served==1&&model.codex.Contains("mimi")&&model.stolenCoins==0,"Interrupted visit settlement invalid");
            }
            foreach(int coins in new[]{0,3,10})
            {
                var model=MimiOrder();var guest=model.At(3);model.coins=coins;model.direction=0;model.Update(3.1f);
                model.direction=3;model.Update(2.1f);
                Require(guest.mimiAttempted&&model.coins==Math.Max(0,coins-5)&&model.stolenCoins==Math.Min(5,coins),"Mimi cap or facing-only behavior invalid");
                int remaining=model.coins;model.direction=0;model.Update(6);
                Require(model.coins==remaining,"Mimi stole twice during same visit");
                model.ended=true;int income;Require(model.TryClaimSettlement(out income)&&income==remaining&&!model.TryClaimSettlement(out income),"Mimi net settlement not once");
            }
            var assist=MimiOrder(true);assist.direction=0;assist.Update(5.2f);
            Require(assist.At(3).MimiWarning&&assist.coins==10,"Assist warning not extended");assist.Update(2.1f);Require(assist.coins==5,"Assist theft did not resolve");
            var early=MimiOrder();early.Update(3.1f);early.direction=0;early.Interact();early.direction=3;early.Interact();early.direction=0;early.Update(6);
            Require(early.coins==10&&early.stolenCoins==0,"Delivered Mimi stole");
            var expired=MimiOrder();expired.direction=0;expired.Update(3.1f);expired.At(3).patience=.001f;expired.Update(.1f);
            Require(expired.visitors.Count==0&&expired.coins==10&&expired.ready==null&&expired.queue.Count==0,"Expired Mimi stole or left cup");
            var ended=MimiOrder();ended.direction=0;ended.Update(3.1f);ended.elapsed=ended.Day.Duration-.01f;ended.Update(10);
            Require(ended.ended&&ended.coins==10,"Mimi advanced after day end");
        }
        static TavernModel GeckoOrder()
        {
            var day=new DayConfiguration(60,10,new[]{DayConfiguration.CreateGecko()},new[]{new ArrivalDefinition(1,0,7)});
            var model=new TavernModel(day){started=true};model.Update(1.1f);model.direction=7;model.Interact();return model;
        }
        static void CheckGecko()
        {
            // Exercise each cup location at the moment of moving.
            foreach(int phase in new[]{0,1,2})
            {
                var model=GeckoOrder();var guest=model.At(7);var cup=model.queue[0];
                if(phase==0)model.brewSpeed=.1f;
                model.Update(3.1f);Require(guest.GeckoMoveWarning,"Gecko warning missing");
                float wait=guest.geckoWait,patience=guest.patience;
                model.paused=true;model.Update(10);Require(guest.geckoWait==wait&&guest.patience==patience&&guest.seat==7,"Pause advanced Gecko move");model.paused=false;
                model.Update(1.1f);
                if(phase==2){model.direction=0;model.Interact();Require(model.hand==cup,"Gecko cup pickup failed");}
                // P1 occupied and P2 blocked: next valid seat is P3, wrapping from P7.
                model.visitors.Add(new Visit{id=99,seat=1,blocked=2,guest=DayConfiguration.CreateTank(),state=VisitState.Order});
                patience=guest.patience;model.Update(1);
                Require(guest.seat==3&&model.At(7)==null&&model.At(3)==guest&&guest.geckoMoveAttempted&&!guest.GeckoMoveWarning,"Gecko move/occupancy invalid");
                Require(guest.patience<patience&&cup.owner==guest.id,"Gecko reset patience or changed cup owner");
                Require(phase==0?model.queue.Count==1&&model.queue[0]==cup:phase==1?model.ready==cup:model.hand==cup,"Gecko lost/recreated cup when moving");
                model.direction=7;model.Interact();Require(guest.state==VisitState.Waiting,"Old seat accepted delivery");
                if(phase==0){model.brewSpeed=1;model.Update(4);}
                if(model.hand==null){model.direction=0;model.Interact();}
                int target;model.ServiceHint(out target);Require(target==3,"Held-cup guidance did not follow Gecko");
                model.direction=3;model.Interact();model.Update(2.1f);model.Interact();int coins=model.coins;model.Interact();
                Require(model.served==1&&model.coins==coins&&model.codex.Contains("gecko")&&model.At(3)==null,"Gecko collection duplicated or failed");
            }
            var early=GeckoOrder();var servedGuest=early.At(7);early.Update(4.1f);early.direction=0;early.Interact();early.direction=7;early.Interact();early.Update(2.1f);
            Require(servedGuest.seat==7&&!servedGuest.geckoMoveAttempted&&!servedGuest.GeckoMoveWarning,"Delivered Gecko moved");
            var full=GeckoOrder();var staying=full.At(7);
            for(int seat=1;seat<=6;seat++)full.visitors.Add(new Visit{id=100+seat,seat=seat,guest=DayConfiguration.CreateTank(),state=VisitState.Order});
            full.Update(5.1f);Require(staying.seat==7&&staying.geckoMoveAttempted,"Full seats caused invalid move");
            full.visitors.RemoveAt(1);full.Update(1);Require(staying.seat==7,"Gecko retried a skipped move");
            var timeout=GeckoOrder();var leaving=timeout.At(7);timeout.Update(5.1f);timeout.direction=0;timeout.Interact();timeout.Update(30);
            Require(timeout.visitors.Count==0&&timeout.queue.Count==0&&timeout.ready==null&&timeout.hand==null&&timeout.missed==1,"Moved Gecko left orphan occupancy or cup");
            var expiry=GeckoOrder();var expiring=expiry.At(7);expiring.geckoWait=4.99f;expiring.patience=.001f;expiry.Update(.05f);
            Require(expiry.visitors.Count==0&&!expiring.geckoMoveAttempted,"Expired Gecko moved before removal");
        }
        static void CheckThirdDay()
        {
            foreach(bool assisted in new[]{false,true})
            {
                var day=new TavernModel(DayConfiguration.ForDay(3),assisted){started=true};
                for(int step=0;step<2500&&!day.ended;step++)
                {
                    foreach(var visitor in day.visitors.ToArray())
                    {
                        day.direction=visitor.seat;
                        if(visitor.state==VisitState.Order||visitor.state==VisitState.Payment||visitor.MimiWarning)day.Interact();
                    }
                    if(day.ready!=null&&day.hand==null){day.direction=0;day.Interact();}
                    if(day.hand!=null){var owner=day.visitors.Find(v=>v.id==day.hand.owner);Require(owner!=null,"Day3 orphan cup");day.direction=owner.seat;day.Interact();}
                    day.Update(.05f);
                }
                Require(day.ended&&day.Passed&&day.served==9&&day.missed==0&&day.coins==190&&day.stolenCoins==0&&day.codex.Count==7,"Perfect Day3 expected 9 served / 190 coins / 7 codex, got "+day.served+" / "+day.coins);
                Require(day.visitors.Count==0&&day.queue.Count==0&&day.ready==null&&day.hand==null,"Day3 left unfinished orders");
                Require(day.TryClaimSettlement(out int income)&&income==190&&!day.TryClaimSettlement(out income),"Day3 duplicate settlement");
                var retry=new TavernModel(DayConfiguration.ForDay(3),assisted);
                Require(retry.Day.TargetCoins==140&&retry.Day.Arrivals.Count==9&&retry.elapsed==0&&retry.coins==0&&retry.stolenCoins==0&&retry.Assisted==assisted,"Day3 retry leaked transient state");
            }
            var idle=new TavernModel(DayConfiguration.ThirdDay()){started=true};idle.Update(120);
            Require(idle.ended&&!idle.Passed&&idle.served==0&&idle.coins==0&&idle.codex.Count==0,"Idle Day3 passed or unlocked codex");
            Require(DayConfiguration.CreateAvailableGuests().Length==7&&DayConfiguration.SecondDay().Guests.Count==5,"Day3 changed Day2 roster or lost codex guests");
        }
        static void CheckSecondDay()
        {
            foreach(bool assisted in new[]{false,true})
            {
                var day=new TavernModel(DayConfiguration.ForDay(2),assisted){started=true};
                for(int step=0;step<2500&&!day.ended;step++)
                {
                    foreach(var visitor in day.visitors.ToArray())
                    {day.direction=visitor.seat;if(visitor.state==VisitState.Order||visitor.state==VisitState.Payment)day.Interact();}
                    if(day.ready!=null&&day.hand==null){day.direction=0;day.Interact();}
                    if(day.hand!=null){var owner=day.visitors.Find(v=>v.id==day.hand.owner);Require(owner!=null,"Day2 orphan cup");day.direction=owner.seat;day.Interact();}
                    day.Update(.05f);
                }
                Require(day.ended&&day.Passed&&day.served==7&&day.missed==0&&day.coins==124&&day.codex.Count==5,"Perfect Day2 expected 7 guests / 124 coins / 5 codex, got "+day.served+" / "+day.coins);
                Require(day.TryClaimSettlement(out int income)&&income==124&&!day.TryClaimSettlement(out income),"Day2 duplicate settlement");
                var retry=new TavernModel(DayConfiguration.ForDay(2),assisted);
                Require(retry.Day.TargetCoins==90&&retry.Day.Arrivals.Count==7&&retry.elapsed==0&&retry.coins==0&&retry.Assisted==assisted,"Day2 retry lost configuration");
            }
            bool refused=false;try{DayConfiguration.ForDay(4);}catch(ArgumentOutOfRangeException){refused=true;}
            Require(refused&&!DayConfiguration.IsPlayable(0)&&!DayConfiguration.IsPlayable(4),"Unimplemented day exposed");
        }
        public static string Run()
        {
            ProgressChecks.Run();
            CheckSecondDay();
            CheckThirdDay();
            var custom=new TavernModel(new DayConfiguration(10,5,DayConfiguration.CreateFirstDayGuests(),new[]{new ArrivalDefinition(1,1,7)})){started=true};
            custom.Update(1.1f);Require(custom.visitors.Count==1&&custom.At(7).guest.id=="coco","Configured guest/seat not used");
            custom.coins=5;custom.Update(9);Require(custom.ended&&custom.elapsed==10&&custom.Passed,"Configured duration/target not used");
            bool rejected=false;
            try{new DayConfiguration(10,5,DayConfiguration.CreateFirstDayGuests(),new[]{new ArrivalDefinition(1,0,0)});}catch(ArgumentException){rejected=true;}
            Require(rejected,"Outlet must not be accepted as an arrival seat");
            rejected=false;
            try{new DayConfiguration(10,5,DayConfiguration.CreateFirstDayGuests(),new[]{new ArrivalDefinition(2,0,1),new ArrivalDefinition(1,0,2)});}catch(ArgumentException){rejected=true;}
            Require(rejected,"Out-of-order arrivals must be rejected");
            var normal=new TavernModel{started=true};
            var gentle=new TavernModel(assisted:true){started=true};
            normal.Update(8.1f);gentle.Update(8.1f);
            float np=normal.visitors[0].patience,gp=gentle.visitors[0].patience;
            normal.Update(1);gentle.Update(1);
            Require(Math.Abs((np-normal.visitors[0].patience)*.75f-(gp-gentle.visitors[0].patience))<.001f,"Assistance patience rate incorrect");
            Require(normal.Day.TargetCoins==gentle.Day.TargetCoins&&normal.Day.Duration==gentle.Day.Duration,"Assistance changed target or duration");
            normal.visitors[0].state=gentle.visitors[0].state=VisitState.Drinking;
            normal.visitors[0].timer=gentle.visitors[0].timer=.01f;
            normal.Update(.02f);gentle.Update(.02f);
            Require(normal.visitors[0].timer==6&&gentle.visitors[0].timer==9,"Assistance payment window incorrect");
            gentle.paused=true;float frozen=gentle.visitors[0].timer;gentle.Update(5);
            Require(gentle.visitors[0].timer==frozen,"Assisted pause changed payment timer");
            gentle.ended=true;gentle.coins=12;
            Require(gentle.TryClaimSettlement(out int assistedIncome)&&assistedIncome==12&&!gentle.TryClaimSettlement(out assistedIncome),"Assisted payout duplicated");
            var retry=new TavernModel(custom.Day,assisted:true){started=true};
            Require(retry.Day==custom.Day&&retry.Assisted&&retry.elapsed==0&&retry.coins==0&&retry.visitors.Count==0&&retry.queue.Count==0&&retry.hand==null&&retry.ready==null,"Retry retained transient state or lost configuration");
            var tankDay=new DayConfiguration(40,10,new[]{DayConfiguration.CreateTank()},new[]{new ArrivalDefinition(1,0,3)});
            var tank=new TavernModel(tankDay){started=true};tank.Update(1.1f);tank.direction=3;
            var diver=tank.At(3);float tankPatience=diver.patience;
            tank.Interact();Require(diver.tankReady&&diver.state==VisitState.Order&&tank.queue.Count==0&&diver.patience==tankPatience,"Tank first interaction must only remove breathing gear");
            tank.paused=true;tank.Interact();Require(tank.queue.Count==0,"Paused Tank accepted order");tank.paused=false;
            tank.Interact();tank.Interact();Require(tank.queue.Count==1&&diver.state==VisitState.Waiting,"Tank second interaction duplicated order");
            tank.Update(5.1f);tank.direction=0;tank.Interact();tank.direction=3;tank.Interact();tank.Update(2.1f);tank.Interact();
            Require(tank.served==1&&tank.codex.Contains("tank")&&tank.At(3)==null,"Tank full service did not finish");
            var abandonedTank=new TavernModel(tankDay){started=true};abandonedTank.Update(1.1f);abandonedTank.direction=3;abandonedTank.Interact();abandonedTank.direction=0;abandonedTank.Update(30);
            Require(abandonedTank.visitors.Count==0&&abandonedTank.queue.Count==0&&abandonedTank.missed==1&&!abandonedTank.codex.Contains("tank"),"Tank attention step prevented timeout or unlocked codex early");
            CheckGecko();
            CheckMimi();
            CheckSpf8();
            CheckSnowy();
            var guide=FirstGuest();int target;
            guide.ServiceHint(out target);Require(target==guide.visitors[0].seat,"Guide must point at first order");
            guide.direction=target;guide.Interact();guide.ServiceHint(out target);Require(target==-1,"Brewing must not point at an empty outlet");
            guide.Update(3.1f);guide.ServiceHint(out target);Require(target==0,"Ready cup must guide to outlet");
            guide.direction=0;guide.Interact();guide.ServiceHint(out target);Require(target==guide.visitors[0].seat,"Held cup must guide to its owner");
            var guideCup=guide.hand;float guideTime=guide.elapsed;guide.ServiceHint(out target);
            Require(guide.hand==guideCup&&guide.elapsed==guideTime,"Guidance mutated gameplay");
            guide.direction=target;guide.Interact();guide.Update(2.1f);guide.ServiceHint(out target);Require(target==guide.visitors[0].seat,"Guide must point to payment");
            guide.direction=target;guide.Interact();guide.ServiceHint(out target);Require(target==-1,"Guide retained departed target");
            guide.ended=true;guide.ServiceHint(out target);Require(target==-1,"Ended day retained tutorial target");
            var m=new TavernModel{started=true};
            Require(!m.TryClaimSettlement(out int income)&&income==0,"Unfinished day allowed settlement");
            for(int i=0;i<2500&&!m.ended;i++)
            {
                foreach(var v in m.visitors.ToArray())
                {m.direction=v.seat;if(v.state==VisitState.Order||v.state==VisitState.Payment)m.Interact();}
                if(m.ready!=null&&m.hand==null){m.direction=0;m.Interact();}
                if(m.hand!=null){var owner=m.visitors.Find(v=>v.id==m.hand.owner);Require(owner!=null,"Orphan cup");m.direction=owner.seat;m.Interact();}
                m.Update(.05f);
            }
            Require(m.ended&&m.Passed&&m.served==5&&m.coins==79,"Perfect day must serve 5 and earn 79, got "+m.served+" / "+m.coins);
            Require(m.codex.Count==3,"Perfect day should unlock 3 guests");
            int coins=m.coins;m.Interact();m.Update(20);Require(m.coins==coins,"Ended day paid twice");
            Require(m.TryClaimSettlement(out income)&&income==79,"Finished day did not pay its income");
            for(int i=0;i<10;i++)Require(!m.TryClaimSettlement(out income)&&income==0,"Repeated settlement paid twice");
            var nextDay=new TavernModel{ended=true,coins=12};
            Require(nextDay.TryClaimSettlement(out income)&&income==12,"New day retained previous settlement lock");
            var zeroDay=new TavernModel{ended=true};
            Require(zeroDay.TryClaimSettlement(out income)&&income==0&&!zeroDay.TryClaimSettlement(out income),"Zero-income day must settle exactly once");

            var paused=FirstGuest();paused.paused=true;float elapsed=paused.elapsed, patience=paused.visitors[0].patience;int direction=paused.direction;
            paused.Update(40);paused.Turn(1);paused.Interact();
            Require(paused.elapsed==elapsed&&paused.visitors[0].patience==patience&&paused.direction==direction&&paused.queue.Count==0,"Pause changed simulation state");

            var orders=FirstGuest();orders.direction=orders.visitors[0].seat;orders.Interact();orders.Interact();
            Require(orders.queue.Count==1,"Repeated interaction duplicated order");orders.Update(3.1f);
            Require(orders.ready!=null,"Drink not ready");orders.direction=0;orders.Interact();orders.Interact();
            Require(orders.hand!=null&&orders.ready==null,"Repeated pickup lost cup");
            var cup=orders.hand;var guest=orders.visitors[0];
            var other=new Visit{id=99,seat=7,guest=TavernModel.Guests[1],state=VisitState.Waiting};orders.visitors.Add(other);
            orders.direction=7;orders.Interact();Require(orders.hand==cup&&other.patience==23,"Wrong cup must remain held with 2s penalty");
            orders.direction=guest.seat;orders.Interact();Require(orders.hand==null&&guest.state==VisitState.Drinking,"Correct delivery failed");
            orders.Update(2.1f);orders.direction=guest.seat;orders.Interact();coins=orders.coins;orders.Interact();
            Require(orders.coins==coins&&orders.At(guest.seat)==null,"Repeated collection paid twice");

            foreach(float remaining in new[]{2f,1f})
            {
                var expiry=FirstGuest();var leaving=expiry.visitors[0];
                expiry.direction=leaving.seat;expiry.Interact();leaving.patience=remaining;leaving.blocked=7;
                var held=new Cup{owner=99,drink="Other order"};expiry.hand=held;
                expiry.ready=new Cup{owner=leaving.id};expiry.combo=3;
                expiry.Interact();
                Require(expiry.At(leaving.seat)==null&&expiry.missed==1&&expiry.combo==0,"Wrong delivery must immediately remove an impatient guest");
                Require(expiry.queue.Count==0&&expiry.ready==null&&!expiry.Blocked(7),"Departure left owned drinks or blocked seat");
                Require(expiry.hand==held,"Departure removed another guest's held cup");
                expiry.Interact();expiry.Update(.05f);
                Require(expiry.missed==1&&expiry.coins==0,"Departed guest was processed twice");
            }

            var abandoned=FirstGuest();abandoned.direction=abandoned.visitors[0].seat;abandoned.Interact();abandoned.direction=0;abandoned.Update(3.1f);abandoned.Interact();
            int ownerId=abandoned.hand.owner;abandoned.Update(30);
            Require(abandoned.visitors.Find(v=>v.id==ownerId)==null&&abandoned.hand==null,"Departed guest left an orphan held cup");

            var boosted=new TavernModel{started=true,patienceMultiplier=1.05f,brewSpeed=1.05f};boosted.Update(8.1f);
            Require(boosted.visitors[0].patience>25,"Patience upgrade failed");boosted.direction=boosted.visitors[0].seat;boosted.Interact();boosted.Update(2.9f);
            Require(boosted.ready!=null,"Brew upgrade failed");
            return "PASS: perfect day 79 coins / 5 served / 3 codex; settlement exactly once; ended lock; pause; duplicate order/pickup/payment; wrong/correct delivery; immediate patience expiry; abandoned cup cleanup; decoration modifiers.";
        }
    }
}
