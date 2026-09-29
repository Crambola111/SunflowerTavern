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
            var future=new MemoryStorage();future.SetInt("sunflower.progress.version",2);int writes=future.writes;bool refused=false;
            try{new ProgressStore(future);}catch(InvalidOperationException){refused=true;}
            Require(refused&&future.writes==writes,"Future schema was overwritten");
            var fresh=new ProgressStore(new MemoryStorage());Require(fresh.Wallet==0&&!fresh.TutorialDone&&!fresh.Owns(0),"Fresh save has stale progress");
        }
    }
}
