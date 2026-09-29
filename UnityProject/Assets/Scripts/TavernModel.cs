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
        public float patience=25, timer, bubble=2.5f;
    }
    public sealed class Cup { public int owner; public string drink; public float remaining, duration; }
    public sealed class TavernModel
    {
        // Visual identities follow the supplied lineup, not the previous web placeholders.
        public static readonly GuestDefinition[] Guests = {
            new GuestDefinition("bobo","Bobo · 冲浪海牛","芒果冰沙",10,3,0,"来岛上三天，冲浪板下水零次。每天都说：明天浪好，我再出手。"),
            new GuestDefinition("coco","Coco · 寄居蟹","椰子水",14,5,2,"旅行只带一点行李：自己的房子和房子的备用房子。"),
            new GuestDefinition("horn","Horn · 犀鸟导游","青柠苏打",12,4,4,"讲景点能讲三小时，点单却只说两秒半：职业之外，节约用嗓。")
        };
        readonly float[] arrival={8,25,48,75,96};
        readonly int[] kinds={0,2,1,0,2}, seats={2,5,3,6,1};
        readonly bool[] spawned=new bool[5];
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
        public bool Passed => ended && coins>=70;
        public Visit At(int seat) => visitors.Find(v=>v.seat==seat);
        public bool Blocked(int seat) => visitors.Any(v=>v.blocked==seat && seat!=0);
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
                    v.state=VisitState.Waiting;v.bubble=2.5f;
                    queue.Add(new Cup{owner=v.id,drink=v.guest.drink,remaining=v.guest.brew,duration=v.guest.brew});
                    message="订单已送到出酒口，自动开始制作。";break;
                case VisitState.Waiting:
                    if(hand==null){v.bubble=2.5f;message=v.guest.name+"："+v.guest.drink;break;}
                    if(hand.owner!=v.id){
                        v.patience=Math.Max(0,v.patience-2);v.bubble=2.5f;
                        if(v.patience<=0)Miss(v);
                        else message="不是这位客人的杯子，耐心 -2 秒。";
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
            elapsed=Math.Min(120,elapsed+dt);
            for(int i=0;i<arrival.Length;i++) {
                if(spawned[i]||elapsed<arrival[i])continue;
                if(elapsed>arrival[i]+6){spawned[i]=true;continue;}
                if(visitors.Count>=2)continue;
                int seat=0;for(int n=0;n<7;n++){int s=(seats[i]-1+n)%7+1;if(At(s)==null&&!Blocked(s)){seat=s;break;}}
                if(seat==0)continue;
                var v=new Visit{id=i,seat=seat,guest=Guests[kinds[i]],state=VisitState.Order,patience=25*patienceMultiplier};
                if(v.guest.id=="coco"){int b=seat%7+1;if(At(b)==null&&!Blocked(b))v.blocked=b;}
                visitors.Add(v);spawned[i]=true;message=v.guest.name+" 入座了！";
            }
            foreach(var v in visitors.ToArray()) {
                v.bubble=Math.Max(0,v.bubble-dt);
                if(v.state==VisitState.Order||v.state==VisitState.Waiting){v.patience-=dt*(direction==v.seat?.5f:1);if(v.patience<=0)Miss(v);}
                else {v.timer-=dt;if(v.timer<=0){if(v.state==VisitState.Drinking){v.state=VisitState.Payment;v.timer=v.guest.id=="bobo"?6:12;}else Miss(v);}}
            }
            if(ready==null&&queue.Count>0){queue[0].remaining-=dt*brewSpeed;if(queue[0].remaining<=0){ready=queue[0];queue.RemoveAt(0);message="饮品做好了，去出酒口取杯。";}}
            if(elapsed>=120){ended=true;message=Passed?"首日目标达成！":"今天差一点，重开再试一次。";}
        }
    }
}
