using System;
using System.Collections.Generic;
using System.Linq;

namespace Sunflower
{
    public enum VisitState { Order, Waiting, Drinking, Payment }
    [Serializable] public sealed class GuestDefinition
    {
        public string id, name, drink, bio;
        public int price, portrait;
        public float brew;
        public GuestDefinition(string id, string name, string drink, int price, float brew, int portrait, string bio)
        { this.id=id; this.name=name; this.drink=drink; this.price=price; this.brew=brew; this.portrait=portrait; this.bio=bio; }
    }
    public sealed class Visit
    {
        public int id, seat, blocked, tip;
        public GuestDefinition guest;
        public VisitState state;
        public bool tankReady;
        public bool geckoMoveAttempted;
        public float geckoWait;
        public bool GeckoMoveWarning=>guest.id=="gecko"&&state==VisitState.Waiting&&!geckoMoveAttempted&&geckoWait>=3;
        public bool NeedsTankAttention=>guest.id=="tank"&&!tankReady;
        public float patience=25, timer, bubble=2.5f;
    }
    public sealed class Cup { public int owner; public string drink; public float remaining, duration; }
    public sealed class TavernModel
    {
        // Visual identities follow the supplied lineup, not the previous web placeholders.
        public static readonly GuestDefinition[] Guests=DayConfiguration.CreateFirstDayGuests();
        public readonly DayConfiguration Day;
        readonly bool[] spawned;
        public readonly bool Assisted;
        public TavernModel(DayConfiguration day=null,bool assisted=false)
        {Day=day??DayConfiguration.FirstDay();Assisted=assisted;spawned=new bool[Day.Arrivals.Count];}
        public readonly List<Visit> visitors=new List<Visit>();
        public readonly List<Cup> queue=new List<Cup>();
        public readonly HashSet<string> codex=new HashSet<string>();
        public Cup ready, hand;
        public float elapsed;
        public float patienceMultiplier=1, brewSpeed=1, tipMultiplier=1;
        public float tipRemainder;
        public int direction, coins, combo, bestCombo, served, missed;
        public bool started, paused, ended;
        bool settlementClaimed;
        // A day owns its payout; reopening UI cannot claim it again.
        public bool TryClaimSettlement(out int income)
        {
            income=0;
            if(!ended||settlementClaimed)return false;
            settlementClaimed=true;income=coins;return true;
        }
        public string message="欢迎来到南风岛。开始营业后，面向客人接单。";
        public bool Passed => ended && coins>=Day.TargetCoins;
        public Visit At(int seat) => visitors.Find(v=>v.seat==seat);
        public bool Blocked(int seat) => visitors.Any(v=>v.blocked==seat && seat!=0);
        // Read-only guidance: derive the next useful action from actual order ownership.
        public string ServiceHint(out int target)
        {
            target=-1;
            if(ended)return "今日营业结束。";
            if(hand!=null){var owner=visitors.Find(v=>v.id==hand.owner);if(owner!=null){target=owner.seat;return "③ 送达：去 P"+target+"，再互动把饮品交给客人。";}}
            var payment=visitors.Where(v=>v.state==VisitState.Payment).OrderBy(v=>v.timer).FirstOrDefault();
            if(payment!=null){target=payment.seat;return "④ 收钱：去 P"+target+" 互动，金币才会入账！";}
            if(ready!=null){target=0;return "② 取杯：饮品做好了，去下方出酒口互动。";}
            if(queue.Count>0)return "② 制作中：饮品会自动做好，留意下方出酒口。";
            var order=visitors.Where(v=>v.state==VisitState.Order).OrderBy(v=>v.patience).FirstOrDefault();
            if(order!=null){target=order.seat;return (order.NeedsTankAttention?"① 提醒Tank摘呼吸器：点击 P":"① 接单：点击 P")+target+" 转向，再次点击与客人交谈。";}
            if(visitors.Any(v=>v.state==VisitState.Drinking))return "④ 等客人喝完，再互动收钱；上酒后还没入账。";
            return "客人正在路上。点击客位可转向，绿色客位是教学目标。";
        }
        public void Turn(int delta) { if(started&&!paused&&!ended) direction=(direction+delta+8)%8; }
        public void Interact()
        {
            if(!started||paused||ended)return;
            if(direction==0) {
                if(hand!=null){message="先把手上的饮品送出去。";return;}
                if(ready!=null){hand=ready;ready=null;message="取杯成功，去杯子标注的座位送达。";}
                else message=queue.Count>0?"正在制作，先照顾其他客人。":"先向客人接单。";
                return;
            }
            var v=At(direction);
            if(v==null){message=Blocked(direction)?"Coco 的行李占着这里。":"这里暂时没有客人。";return;}
            switch(v.state) {
                case VisitState.Order:
                    if(v.NeedsTankAttention)
                    {
                        v.tankReady=true;v.bubble=2.5f;
                        message="Tank 摘下呼吸器：原来这里不是水下免税店。再互动正式接单。";
                        break;
                    }
                    v.state=VisitState.Waiting;v.bubble=2.5f;
                    queue.Add(new Cup{owner=v.id,drink=v.guest.drink,remaining=v.guest.brew,duration=v.guest.brew});
                    message="订单已送到出酒口，自动开始制作。";break;
                case VisitState.Waiting:
                    if(hand==null){v.bubble=2.5f;message=v.guest.name+"："+v.guest.drink;break;}
                    if(hand.owner!=v.id){
                        v.patience=Math.Max(0,v.patience-2);v.bubble=2.5f;
                        if(v.patience<=0)Miss(v);
                        else {var owner=visitors.Find(g=>g.id==hand.owner);message="送错了，耐心 -2 秒。"+(owner==null?"":"这杯请送到 P"+owner.seat+"。");}
                        break;
                    }
                    hand=null;v.tip=v.patience>=17.5f?3:v.patience>=7.5f?1:0;v.state=VisitState.Drinking;v.timer=2;
                    message="送达！喝完之后记得收钱。";break;
                case VisitState.Payment:
                    combo++;bestCombo=Math.Max(combo,bestCombo);int gain=v.guest.price+v.tip+Math.Min(5,Math.Max(0,combo-2));
                    tipRemainder+=v.tip*Math.Max(0,tipMultiplier-1);
                    int extra=(int)Math.Floor(tipRemainder);tipRemainder-=extra;gain+=extra;
                    coins+=gain;served++;codex.Add(v.guest.id);Remove(v);message="收到 "+gain+" 金币！";break;
                default:message="客人正在喝饮品。";break;
            }
        }
        void UpdateGecko(Visit v,float dt)
        {
            if(v.guest.id!="gecko"||v.state!=VisitState.Waiting||v.geckoMoveAttempted)return;
            v.geckoWait+=dt;
            if(v.geckoWait<5)return;
            v.geckoMoveAttempted=true;
            // Cup ownership uses visit ID; changing seats never recreates the order.
            int previous=v.seat;
            for(int n=1;n<7;n++)
            {
                int next=(previous-1+n)%7+1;
                if(At(next)!=null||Blocked(next))continue;
                v.seat=next;v.bubble=2.5f;
                message="Gecko：这边光线好。P"+previous+" → P"+next+"，原订单继续！";
                return;
            }
            message="Gecko：没有空座？那先给这张桌子打五星。";
        }
        void Remove(Visit v)
        { visitors.Remove(v);queue.RemoveAll(c=>c.owner==v.id);if(ready?.owner==v.id)ready=null;if(hand?.owner==v.id)hand=null; }
        void Miss(Visit v){missed++;combo=0;Remove(v);message=v.guest.name+" 走了。下一单继续！";}
        public void Update(float delta)
        {
            if(!started||paused||ended||float.IsNaN(delta)||float.IsInfinity(delta)||delta<=0)return;
            while(delta>0&&!ended){float dt=Math.Min(.05f,delta);Tick(dt);delta-=dt;}
        }
        void Tick(float dt)
        {
            elapsed=Math.Min(Day.Duration,elapsed+dt);
            for(int i=0;i<Day.Arrivals.Count;i++) {
                var arrival=Day.Arrivals[i];
                if(spawned[i]||elapsed<arrival.time)continue;
                if(elapsed>arrival.time+6){spawned[i]=true;continue;}
                if(visitors.Count>=2)continue;
                int seat=0;for(int n=0;n<7;n++){int s=(arrival.seat-1+n)%7+1;if(At(s)==null&&!Blocked(s)){seat=s;break;}}
                if(seat==0)continue;
                var v=new Visit{id=i,seat=seat,guest=Day.Guests[arrival.guestIndex],state=VisitState.Order,patience=25*patienceMultiplier};
                if(v.guest.id=="coco"){int b=seat%7+1;if(At(b)==null&&!Blocked(b))v.blocked=b;}
                visitors.Add(v);spawned[i]=true;message=v.guest.name+" 入座了！";
            }
            foreach(var v in visitors.ToArray()) {
                v.bubble=Math.Max(0,v.bubble-dt);
                if(v.state==VisitState.Order||v.state==VisitState.Waiting){v.patience-=dt*(direction==v.seat?.5f:1)*(Assisted?.75f:1);if(v.patience<=0)Miss(v);else UpdateGecko(v,dt);}
                else {v.timer-=dt;if(v.timer<=0){if(v.state==VisitState.Drinking){v.state=VisitState.Payment;v.timer=(v.guest.id=="bobo"?6:12)*(Assisted?1.5f:1);}else Miss(v);}}
            }
            if(ready==null&&queue.Count>0){queue[0].remaining-=dt*brewSpeed;if(queue[0].remaining<=0){ready=queue[0];queue.RemoveAt(0);message="饮品做好了，去出酒口取杯。";}}
            if(elapsed>=Day.Duration){ended=true;message=Passed?"今日目标达成！":"今天差一点，重开再试一次。";}
        }
    }
}
