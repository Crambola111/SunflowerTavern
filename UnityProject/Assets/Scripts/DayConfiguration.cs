using System;
using System.Collections.ObjectModel;

namespace Sunflower
{
    public sealed class ArrivalDefinition
    {
        public readonly float time;
        public readonly int guestIndex, seat;
        public ArrivalDefinition(float time,int guestIndex,int seat)
        {this.time=time;this.guestIndex=guestIndex;this.seat=seat;}
    }

    // Pure C# data: shared by the Unity scene and standalone logic checks.
    public sealed class DayConfiguration
    {
        public readonly float Duration;
        public readonly int TargetCoins;
        public readonly ReadOnlyCollection<GuestDefinition> Guests;
        public readonly ReadOnlyCollection<ArrivalDefinition> Arrivals;

        public DayConfiguration(float duration,int targetCoins,GuestDefinition[] guests,ArrivalDefinition[] arrivals)
        {
            if(float.IsNaN(duration)||float.IsInfinity(duration)||duration<=0)throw new ArgumentException("Day duration must be finite and positive.");
            if(targetCoins<=0)throw new ArgumentException("Target must be positive.");
            if(guests==null||guests.Length==0||arrivals==null||arrivals.Length==0)throw new ArgumentException("Guests and arrivals are required.");
            var copy=new GuestDefinition[guests.Length];
            var ids=new System.Collections.Generic.HashSet<string>();
            for(int i=0;i<guests.Length;i++)
            {
                var g=guests[i];
                if(g==null||string.IsNullOrWhiteSpace(g.id)||!ids.Add(g.id)||string.IsNullOrWhiteSpace(g.name)||string.IsNullOrWhiteSpace(g.drink)||g.price<=0||float.IsNaN(g.brew)||float.IsInfinity(g.brew)||g.brew<=0)
                    throw new ArgumentException("Guest IDs must be unique; names, drinks, price and brew time must be valid.");
                copy[i]=new GuestDefinition(g.id,g.name,g.drink,g.price,g.brew,g.portrait,g.bio);
            }
            float previous=-1;
            foreach(var a in arrivals)
            {
                if(a==null||float.IsNaN(a.time)||float.IsInfinity(a.time)||a.time<0||a.time>=duration||a.time<previous||a.guestIndex<0||a.guestIndex>=copy.Length||a.seat<1||a.seat>7)
                    throw new ArgumentException("Arrival must be ordered, within the day, and refer to a valid guest and seat 1–7.");
                previous=a.time;
            }
            Duration=duration;TargetCoins=targetCoins;
            Guests=Array.AsReadOnly(copy);Arrivals=Array.AsReadOnly((ArrivalDefinition[])arrivals.Clone());
        }

        public static GuestDefinition CreateMimi()=>new GuestDefinition("mimi","Mimi · 猴子游客","芒果冰沙",10,3,6,
            "旅行攻略只有两条：自拍找角度，零钱找机会。被老板抓包就举起手机：别误会，我在拍金币特写。");

        public static GuestDefinition CreateTank()=>new GuestDefinition("tank","Tank · 海龟潜水员","椰子水",14,5,3,
            "上岸半小时还戴着呼吸器。点单全靠冒泡，以为老板也会水下手语。");

        public static GuestDefinition CreateGecko()=>new GuestDefinition("gecko","Gecko · 座位测评员","青柠苏打",12,4,5,
            "饮品还没喝，座位已经测评三轮。记录板上只有一句：隔壁那桌可能更好。");

        public static GuestDefinition[] CreateFirstDayGuests()=>new[]{
            new GuestDefinition("bobo","Bobo · 冲浪海牛","芒果冰沙",10,3,0,"来岛上三天，冲浪板下水零次。每天都说：明天浪好，我再出手。"),
            new GuestDefinition("coco","Coco · 寄居蟹","椰子水",14,5,2,"旅行只带一点行李：自己的房子和房子的备用房子。"),
            new GuestDefinition("horn","Horn · 犀鸟导游","青柠苏打",12,4,4,"讲景点能讲三小时，点单却只说两秒半：职业之外，节约用嗓。")
        };
        public static GuestDefinition[] CreateAvailableGuests()
        {
            var first=CreateFirstDayGuests();
            return new[]{first[0],first[1],first[2],CreateTank(),CreateGecko()};
        }
        public static bool IsPlayable(int day)=>day==1||day==2;
        public static DayConfiguration ForDay(int day)
        {
            if(day==1)return FirstDay();
            if(day==2)return SecondDay();
            throw new ArgumentOutOfRangeException(nameof(day),"This day is not implemented yet.");
        }
        public static DayConfiguration SecondDay()=>new DayConfiguration(120,90,CreateAvailableGuests(),new[]{
            new ArrivalDefinition(8,3,2),new ArrivalDefinition(24,4,7),new ArrivalDefinition(40,0,5),
            new ArrivalDefinition(48,1,3),new ArrivalDefinition(66,2,6),new ArrivalDefinition(84,3,1),
            new ArrivalDefinition(98,4,4)
        });
        public static DayConfiguration FirstDay()=>new DayConfiguration(120,70,CreateFirstDayGuests(),new[]{
            new ArrivalDefinition(8,0,2),new ArrivalDefinition(25,2,5),new ArrivalDefinition(48,1,3),
            new ArrivalDefinition(75,0,6),new ArrivalDefinition(96,2,1)
        });
    }
}
