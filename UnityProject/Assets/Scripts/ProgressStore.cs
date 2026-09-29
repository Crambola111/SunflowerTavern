using System;
using System.Collections.Generic;

namespace Sunflower
{
    public interface IProgressStorage
    {
        int GetInt(string key,int fallback);
        float GetFloat(string key,float fallback);
        void SetInt(string key,int value);
        void SetFloat(string key,float value);
        void Flush();
    }

    // Persist only between-session progress; never resume a half-finished service day.
    public sealed class ProgressStore
    {
        public const int Version=1;
        const string Prefix="sunflower.progress.v1.";
        const string VersionKey="sunflower.progress.version";
        readonly IProgressStorage storage;
        readonly HashSet<string> codex=new HashSet<string>();
        readonly bool[] decorations=new bool[3];
        public int Wallet {get;private set;}
        public float TipRemainder {get;private set;}
        public bool TutorialDone {get;private set;}

        public ProgressStore(IProgressStorage storage)
        {
            this.storage=storage??throw new ArgumentNullException(nameof(storage));
            int version=storage.GetInt(VersionKey,0);
            // Never let an older game overwrite progress written by a newer schema.
            if(version<0||version>Version)throw new InvalidOperationException("存档版本不受支持，请使用匹配的游戏版本。原存档未修改。");
            bool migrate=version==0;
            string source=migrate?"sunflower.island.":Prefix;
            Wallet=Math.Max(0,storage.GetInt(source+"wallet",0));
            float remainder=storage.GetFloat(source+"tipRemainder",0);
            TipRemainder=float.IsNaN(remainder)||float.IsInfinity(remainder)||remainder<0||remainder>=1?0:remainder;
            TutorialDone=storage.GetInt(source+"tutorialDone",0)==1;
            for(int i=0;i<3;i++)decorations[i]=storage.GetInt(source+"decor."+i,0)==1;
            foreach(string id in new[]{"bobo","coco","horn","tank","gecko","mimi","spf8","snowy","jiwoo"})
                if(storage.GetInt((migrate?"sunflower.codex.":Prefix+"codex.")+id,0)==1)codex.Add(id);
            if(migrate)Save(); // Old keys remain untouched for recovery, never added twice.
        }

        public bool Owns(int index)=>index>=0&&index<decorations.Length&&decorations[index];
        public bool Knows(string id)=>codex.Contains(id);
        public void Unlock(string id){if(!string.IsNullOrWhiteSpace(id)&&codex.Add(id))Save();}
        public void CompleteTutorial(){if(TutorialDone)return;TutorialDone=true;Save();}
        public bool Purchase(int index,int price)
        {
            if(index<0||index>=decorations.Length||price<=0||Owns(index)||Wallet<price)return false;
            Wallet-=price;decorations[index]=true;Save();return true;
        }
        // Caller must obtain the model's one-time settlement claim first.
        public void AddSettlement(int income,float remainder)
        {
            if(income<0||float.IsNaN(remainder)||float.IsInfinity(remainder)||remainder<0||remainder>=1)
                throw new ArgumentException("Invalid settlement.");
            Wallet=(int)Math.Min(int.MaxValue,(long)Wallet+income);TipRemainder=remainder;Save();
        }
        void Save()
        {
            storage.SetInt(Prefix+"wallet",Wallet);storage.SetFloat(Prefix+"tipRemainder",TipRemainder);
            storage.SetInt(Prefix+"tutorialDone",TutorialDone?1:0);
            for(int i=0;i<3;i++)storage.SetInt(Prefix+"decor."+i,decorations[i]?1:0);
            foreach(var id in codex)storage.SetInt(Prefix+"codex."+id,1);
            storage.Flush(); // Commit version only after migration values were flushed.
            storage.SetInt(VersionKey,Version);storage.Flush();
        }
    }
}
