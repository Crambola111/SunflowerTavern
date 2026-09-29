using System;
using System.Collections.Generic;

namespace Sunflower
{
    public static class ProgressChecks
    {
        sealed class MemoryStorage : IProgressStorage
        {
            readonly Dictionary<string,int> ints=new Dictionary<string,int>();
            readonly Dictionary<string,float> floats=new Dictionary<string,float>();
            public int writes;
            public int GetInt(string k,int d)=>ints.TryGetValue(k,out int v)?v:d;
            public float GetFloat(string k,float d)=>floats.TryGetValue(k,out float v)?v:d;
            public void SetInt(string k,int v){ints[k]=v;writes++;}
            public void SetFloat(string k,float v){floats[k]=v;writes++;}
            public void Flush(){}
        }
        static void Require(bool ok,string message){if(!ok)throw new Exception(message);}
        public static void Run()
        {
            var memory=new MemoryStorage();
            memory.SetInt("sunflower.island.wallet",100);memory.SetInt("sunflower.island.decor.0",1);
            memory.SetInt("sunflower.codex.horn",1);memory.SetInt("sunflower.island.tutorialDone",1);
            memory.SetFloat("sunflower.island.tipRemainder",.25f);
            var save=new ProgressStore(memory);
            Require(save.Wallet==100&&save.Owns(0)&&save.Knows("horn")&&save.TutorialDone&&save.TipRemainder==.25f,"Legacy migration lost progress");
            Require(memory.GetInt("sunflower.island.wallet",0)==100,"Migration changed legacy backup");
            Require(save.Purchase(1,45)&&save.Wallet==55&&!save.Purchase(1,45)&&!save.Purchase(2,60),"Purchase must charge once and reject insufficient funds");
            save.AddSettlement(12,.5f);save.Unlock("coco");
            var reloaded=new ProgressStore(memory);
            Require(reloaded.Wallet==67&&reloaded.Owns(1)&&reloaded.Knows("coco")&&reloaded.TipRemainder==.5f,"Reload used legacy values or lost new progress");
            var bad=new MemoryStorage();bad.SetInt("sunflower.island.wallet",-1);bad.SetFloat("sunflower.island.tipRemainder",float.NaN);
            var repaired=new ProgressStore(bad);Require(repaired.Wallet==0&&repaired.TipRemainder==0,"Invalid legacy values not sanitized");
            var future=new MemoryStorage();future.SetInt("sunflower.progress.version",3);int writes=future.writes;bool refused=false;
            try{new ProgressStore(future);}catch(InvalidOperationException){refused=true;}
            Require(refused&&future.writes==writes,"Future schema was overwritten");
            var v1=new MemoryStorage();v1.SetInt("sunflower.progress.version",1);
            v1.SetInt("sunflower.progress.v1.wallet",79);v1.SetInt("sunflower.progress.v1.decor.2",1);v1.SetInt("sunflower.progress.v1.codex.bobo",1);
            var campaign=new ProgressStore(v1);
            Require(campaign.Wallet==79&&campaign.Owns(2)&&campaign.Knows("bobo")&&!campaign.IsCleared(1)&&!campaign.IsUnlocked(2),"v1 migration lost data or invented clears");
            int beforeWrites=v1.writes;bool locked=false;
            try{campaign.CompleteDay(2,100,70,0,false);}catch(ArgumentException){locked=true;}
            Require(locked&&v1.writes==beforeWrites&&campaign.Wallet==79,"Locked day mutated save");
            campaign.CompleteDay(1,60,70,0,false);
            Require(!campaign.IsUnlocked(2)&&campaign.BestIncome(1,false)==60,"Failure unlocked next day");
            campaign.CompleteDay(1,79,70,.25f,true);
            Require(campaign.IsUnlocked(2)&&campaign.IsCleared(1,true)&&!campaign.IsCleared(1,false)&&campaign.BestIncome(1,false)==60,"Assisted clear overwrote standard record");
            campaign.CompleteDay(1,20,70,0,true);
            var loaded=new ProgressStore(v1);
            Require(loaded.BestIncome(1,true)==79&&loaded.IsUnlocked(2)&&loaded.Wallet==238,"Replay or reload lost high score/clear/wallet");
            Require(!loaded.IsUnlocked(0)&&!loaded.IsUnlocked(5)&&!loaded.IsUnlocked(3),"Unlock range incorrect");
            for(int day=2;day<=4;day++)loaded.CompleteDay(day,70,70,0,false);
            Require(loaded.IsCleared(4)&&!loaded.IsUnlocked(5),"Four-day progression exceeded map bounds");
            var malformed=new MemoryStorage();malformed.SetInt("sunflower.progress.version",2);malformed.SetInt("sunflower.progress.v2.day.3.clear.0",1);
            Require(!new ProgressStore(malformed).IsCleared(3),"Orphan clear bypassed ordered progression");
            var fresh=new ProgressStore(new MemoryStorage());Require(fresh.Wallet==0&&!fresh.TutorialDone&&!fresh.Owns(0),"Fresh save has stale progress");
        }
    }
}
