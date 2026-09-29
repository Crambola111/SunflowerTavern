using UnityEngine;

namespace Sunflower
{
    public sealed class PlayerPrefsProgressStorage : IProgressStorage
    {
        public int GetInt(string key,int fallback)=>PlayerPrefs.GetInt(key,fallback);
        public float GetFloat(string key,float fallback)=>PlayerPrefs.GetFloat(key,fallback);
        public void SetInt(string key,int value)=>PlayerPrefs.SetInt(key,value);
        public void SetFloat(string key,float value)=>PlayerPrefs.SetFloat(key,value);
        public void Flush()=>PlayerPrefs.Save();
    }
}
