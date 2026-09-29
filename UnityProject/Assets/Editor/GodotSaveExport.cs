using System;
using System.IO;
using System.Text;
using UnityEditor;
using UnityEngine;

namespace Sunflower.Editor
{
    // Optional one-time bridge. Read-only: never migrates or modifies PlayerPrefs.
    public static class GodotSaveExport
    {
        [MenuItem("Sunflower/Export save for Godot")]
        public static void Export()
        {
            int version = PlayerPrefs.GetInt("sunflower.progress.version", 0);
            if (version < 0 || version > 2) throw new InvalidOperationException("Unsupported save version.");
            string path = EditorUtility.SaveFilePanel("Export Godot save", "", "unity_save", "json");
            if (string.IsNullOrEmpty(path)) return;
            string prefix = version == 0 ? "sunflower.island." : "sunflower.progress.v" + version + ".";
            var json = new StringBuilder("{\"version\":2,\"wallet\":");
            json.Append(Math.Max(0, PlayerPrefs.GetInt(prefix + "wallet", 0)));
            float remainder = PlayerPrefs.GetFloat(prefix + "tipRemainder", 0);
            if (float.IsNaN(remainder) || float.IsInfinity(remainder) || remainder < 0 || remainder >= 1) remainder = 0;
            json.Append(",\"tip_remainder\":").Append(remainder.ToString(System.Globalization.CultureInfo.InvariantCulture));
            json.Append(",\"tutorial_done\":").Append(Flag(prefix + "tutorialDone"));
            json.Append(",\"decorations\":[");
            for (int i = 0; i < 3; i++) { if (i > 0) json.Append(','); json.Append(Flag(prefix + "decor." + i)); }
            json.Append("],\"codex\":[");
            bool first = true;
            foreach (string id in new[] { "bobo", "coco", "horn", "tank", "gecko", "mimi", "spf8", "snowy", "jiwoo" })
            {
                if (PlayerPrefs.GetInt((version == 0 ? "sunflower.codex." : prefix + "codex.") + id, 0) != 1) continue;
                if (!first) json.Append(','); first = false; json.Append('"').Append(id).Append('"');
            }
            json.Append("],\"best\":[");
            for (int day = 1; day <= 4; day++)
            {
                if (day > 1) json.Append(','); json.Append('[');
                for (int mode = 0; mode < 2; mode++) { if (mode > 0) json.Append(','); json.Append(version == 2 ? Math.Max(0, PlayerPrefs.GetInt(prefix + "day." + day + ".best." + mode, 0)) : 0); }
                json.Append(']');
            }
            json.Append("],\"cleared\":[");
            bool unlocked = true;
            for (int day = 1; day <= 4; day++)
            {
                if (day > 1) json.Append(','); json.Append('[');
                bool any = false;
                for (int mode = 0; mode < 2; mode++)
                {
                    bool clear = unlocked && version == 2 && PlayerPrefs.GetInt(prefix + "day." + day + ".clear." + mode, 0) == 1;
                    if (mode > 0) json.Append(','); json.Append(clear ? "true" : "false"); any |= clear;
                }
                json.Append(']'); unlocked = any;
            }
            json.Append("]}");
            File.WriteAllText(path, json.ToString(), new UTF8Encoding(false));
            Debug.Log("Godot save exported: " + path);
        }
        static string Flag(string key) => PlayerPrefs.GetInt(key, 0) == 1 ? "true" : "false";
    }
}
