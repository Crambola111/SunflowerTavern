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
        public static string Run()
        {
            ProgressChecks.Run();
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
