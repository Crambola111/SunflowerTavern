using System;
using System.IO;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
namespace Sunflower.Editor
{
    public static class IslandSetup
    {
        [MenuItem("Sunflower/Check Round 3 Art")]
        public static void CheckRoundThreeArt()
        {
            int ready=0;
            bool combined=ValidArtFile("TableFront_Combined",true);
            for(int i=0;i<8;i++)
            {
                if(i>0&&combined){ready++;continue;}
                string name=i==0?"Horn_Portrait":"TableFront_P"+i;
                string path="Assets/Resources/IslandUI/"+name+".png";
                var texture=AssetDatabase.LoadAssetAtPath<Texture2D>(path);
                if(texture==null){Debug.LogWarning("Missing: "+path);continue;}
                if(i>0&&(texture.width!=1672||texture.height!=941)){Debug.LogWarning(name+": expected 1672x941, do not crop transparent canvas.");continue;}
                // PNG IHDR color type 6 is RGBA. Pixel-level edge/mask alignment still needs visual review.
                byte[] png=File.ReadAllBytes(path);
                if(png.Length<26||png[0]!=137||png[1]!=80||png[2]!=78||png[3]!=71||png[25]!=6){Debug.LogWarning(name+": export RGBA PNG with transparency.");continue;}
                ready++;
            }
            Debug.Log("Round 3 art file checks: "+ready+" / 8. This is NOT visual acceptance; check transparency, character scale and foreground alignment in Game View.");
        }
        static bool ValidArtFile(string name,bool fullCanvas)
        {
            string path="Assets/Resources/IslandUI/"+name+".png";
            var texture=AssetDatabase.LoadAssetAtPath<Texture2D>(path);
            if(texture==null)return false;
            if(fullCanvas&&(texture.width!=1672||texture.height!=941))return false;
            byte[] png=File.ReadAllBytes(path);
            return png.Length>=26&&png[0]==137&&png[1]==80&&png[2]==78&&png[3]==71&&png[25]==6;
        }
        [MenuItem("Sunflower/Create Island Scene")]
        public static void CreateScene()
        {
            if(!EditorSceneManager.SaveCurrentModifiedScenesIfUserWantsTo())return;
            const string path="Assets/Scenes/NanfengIsland.unity";
            if(File.Exists(path)){EditorSceneManager.OpenScene(path);return;}
            Directory.CreateDirectory("Assets/Scenes");
            var scene=EditorSceneManager.NewScene(NewSceneSetup.EmptyScene,NewSceneMode.Single);
            new GameObject("IslandScene",typeof(IslandScene));
            EditorSceneManager.SaveScene(scene,path);
            EditorBuildSettings.scenes=new[]{new EditorBuildSettingsScene(path,true)};
            PlayerSettings.companyName="Sunflower";PlayerSettings.productName="Sunflower Tavern";
            PlayerSettings.defaultScreenWidth=1600;PlayerSettings.defaultScreenHeight=900;
            AssetDatabase.SaveAssets();
        }
        [MenuItem("Sunflower/Run Logic Smoke Checks")]
        public static void Check()
        {
            string report=DayOneChecks.Run();
            foreach(var asset in new[]{"Island_Background","Sunny_Chibi","Bobo_Portrait","Coco_Portrait","Dialogue_Panel","Button_Gold","Codex_Book"})
                if(Resources.Load<Texture2D>("IslandUI/"+asset)==null)throw new Exception("Missing art: "+asset);
            Debug.Log("Sunflower: "+report+" Required runtime art loaded.");
        }
    }
}
