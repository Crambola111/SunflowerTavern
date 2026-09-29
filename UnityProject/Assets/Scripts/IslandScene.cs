using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;

namespace Sunflower
{
    public sealed class IslandScene : MonoBehaviour
    {
        TavernModel model;
        Font font;
        Transform root;
        GameObject modal, arrivalCard;
        Text hud, status, queue, toast;
        Text actionLabel, selectionLabel;
        Text tutorialLabel;
        GameObject tutorialCard;
        bool tutorialEnabled;
        int tutorialBaseline;
        float tutorialCompleteTime;
        Button actionButton;
        readonly GameObject[] guestHits=new GameObject[8];
        RawImage sunny;
        readonly int[] visualVisits={-1,-1,-1,-1,-1,-1,-1,-1};
        readonly float[] guestVisibility=new float[8];
        float servicePulse;
        int serviceDirection;
        readonly Text[] labels=new Text[8];
        readonly Image[] faces=new Image[8];
        readonly RawImage[] guests=new RawImage[8];
        readonly Image[] bars=new Image[8];
        readonly HashSet<int> arrivals=new HashSet<int>();
        readonly Dictionary<string,Texture2D> textures=new Dictionary<string,Texture2D>();
        readonly Dictionary<string,Sprite> sprites=new Dictionary<string,Sprite>();
        readonly Vector2[] seats={new Vector2(800,190),new Vector2(800,680),new Vector2(1080,625),new Vector2(1270,445),new Vector2(1140,280),new Vector2(440,280),new Vector2(270,445),new Vector2(520,625)};
        readonly string[] items={"向日葵花瓶","藤编小灯","顺手托盘"};
        readonly string[] effects={"客人耐心 +5%","小费 +5%（累计取整）","制作速度 +5%"};
        readonly int[] prices={30,45,60};
        const string SaveKey="sunflower.island.";
        bool focusPaused;
        int wallet;
        int inputBlockedFrame=-1;
        float arrivalTime;
        Texture2D hornPortrait, hornFallback;

        void Start()
        {
            font=Font.CreateDynamicFontFromOSFont(new[]{"Microsoft YaHei","Noto Sans CJK SC","PingFang SC","Arial Unicode MS","Arial"},24);
            if(font==null)font=Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            var canvas=new GameObject("IslandCanvas",typeof(Canvas),typeof(CanvasScaler),typeof(GraphicRaycaster));
            canvas.GetComponent<Canvas>().renderMode=RenderMode.ScreenSpaceOverlay;
            var scaler=canvas.GetComponent<CanvasScaler>();scaler.uiScaleMode=CanvasScaler.ScaleMode.ScaleWithScreenSize;scaler.referenceResolution=new Vector2(1600,900);scaler.screenMatchMode=CanvasScaler.ScreenMatchMode.Expand;
            var surround=Solid(canvas.transform,Vector2.zero,Vector2.zero,new Color(.035f,.24f,.29f));
            var surroundRect=surround.GetComponent<RectTransform>();surroundRect.anchorMin=Vector2.zero;surroundRect.anchorMax=Vector2.one;surroundRect.offsetMin=surroundRect.offsetMax=Vector2.zero;
            var area=Node("DesignArea",canvas.transform,Vector2.zero,new Vector2(1600,900));
            var rect=area.GetComponent<RectTransform>();rect.anchorMin=rect.anchorMax=new Vector2(.5f,.5f);root=area.transform;
            var events=FindFirstObjectByType<EventSystem>();
            if(events==null)events=new GameObject("EventSystem",typeof(EventSystem),typeof(StandaloneInputModule)).GetComponent<EventSystem>();
            // Keyboard gameplay commands belong to Update, not the last clicked button.
            // Pointer events remain enabled; prevent Submit/Move from firing a second action.
            events.sendNavigationEvents=false;
            Art(root,new Vector2(800,450),new Vector2(1600,900),"Island_Background");
            sunny=Art(root,new Vector2(800,465),new Vector2(175,175),"Sunny_Chibi");
            var islandUniform=Resources.Load<Texture2D>("IslandUI/Sunny_Southwind_Idle_v1");
            if(islandUniform!=null)sunny.texture=islandUniform;
            hornPortrait=Resources.Load<Texture2D>("IslandUI/Horn_Portrait");
            if(hornPortrait==null){hornFallback=Resources.Load<Texture2D>("Art/GuestLineup");Debug.LogWarning("Round 3 art pending: Horn_Portrait.png. Using lineup placeholder.");}
            var guestLayer=Node("GuestLayer",root,new Vector2(800,450),new Vector2(1600,900)).transform;
            var foreground=Node("TableForegroundLayer",root,new Vector2(800,450),new Vector2(1600,900)).transform;
            var combined=Resources.Load<Texture2D>("IslandUI/TableFront_Combined");
            bool useCombined=combined!=null&&combined.width==1672&&combined.height==941;
            if(useCombined){var front=Node("TableFront_Combined",foreground,new Vector2(800,450),new Vector2(1600,900)).AddComponent<RawImage>();front.texture=combined;front.raycastTarget=false;}
            else if(combined!=null)Debug.LogWarning("Skipped combined foreground: expected 1672x941.");
            for(int i=1;!useCombined&&i<=7;i++)
            {
                var mask=Resources.Load<Texture2D>("IslandUI/TableFront_P"+i);
                if(mask==null){Debug.LogWarning("Round 3 art pending: TableFront_P"+i+".png");continue;}
                if(mask.width!=1672||mask.height!=941){Debug.LogWarning("Skipped TableFront_P"+i+": expected full 1672x941 canvas.");continue;}
                var front=Node("TableFront_P"+i,foreground,new Vector2(800,450),new Vector2(1600,900)).AddComponent<RawImage>();
                front.texture=mask;front.raycastTarget=false;
            }
            for(int i=0;i<8;i++)
            {
                int n=i;
                if(i>0){guests[i]=Art(guestLayer,seats[i]+new Vector2(-30,35),new Vector2(130,130),"Bobo_Portrait");guests[i].gameObject.SetActive(false);}
                if(i>0){var hit=Solid(root,seats[i]+new Vector2(-30,35),new Vector2(150,140),Color.clear);guestHits[i]=hit;hit.name="GuestHit_P"+i;var hitButton=hit.AddComponent<Button>();hitButton.transition=Selectable.Transition.None;hitButton.onClick.AddListener(()=>Select(n));}
                var b=MakeButton(root,seats[i]+new Vector2(0,i==0?-50:-65),new Vector2(190,64),"",()=>Select(n));
                labels[i]=b.GetComponentInChildren<Text>();faces[i]=b.GetComponent<Image>();
                if(i>0){labels[i].fontSize=18;var track=Solid(root,seats[i]+new Vector2(0,-103),new Vector2(145,7),new Color(.25f,.16f,.08f));track.GetComponent<Image>().raycastTarget=false;bars[i]=Solid(track.transform,new Vector2(72.5f,3.5f),new Vector2(145,7),new Color(.35f,.72f,.29f)).GetComponent<Image>();bars[i].raycastTarget=false;}
            }
            Card(root,new Vector2(800,850),new Vector2(1540,88));
            hud=Label(root,new Vector2(760,850),new Vector2(1390,65),"",25);
            MakeButton(root,new Vector2(1520,850),new Vector2(65,50),"Ⅱ",Pause);
            MakeButton(root,new Vector2(100,65),new Vector2(150,64),"客人图鉴",()=>Codex(0));
            MakeButton(root,new Vector2(270,65),new Vector2(150,64),"装饰酒馆",Shop);
            MakeButton(root,new Vector2(1300,65),new Vector2(70,64),"←",()=>Turn(-1));
            actionButton=MakeButton(root,new Vector2(1400,65),new Vector2(120,64),"互动",Interact);actionLabel=actionButton.GetComponentInChildren<Text>();
            MakeButton(root,new Vector2(1500,65),new Vector2(70,64),"→",()=>Turn(1));
            Card(root,new Vector2(1400,132),new Vector2(300,46));selectionLabel=Label(root,new Vector2(1400,132),new Vector2(280,34),"",18);
            Card(root,new Vector2(800,55),new Vector2(780,82));queue=Label(root,new Vector2(800,73),new Vector2(740,32),"",20);
            status=Label(root,new Vector2(800,37),new Vector2(740,30),"",18);
            tutorialCard=Card(root,new Vector2(800,119),new Vector2(780,40));
            tutorialLabel=Label(tutorialCard.transform,new Vector2(390,20),new Vector2(755,36),"",18);
            arrivalCard=Card(root,new Vector2(280,760),new Vector2(480,70));toast=Label(arrivalCard.transform,new Vector2(240,35),new Vector2(440,50),"",21);
            wallet=PlayerPrefs.GetInt(SaveKey+"wallet",0);ResetDay();Welcome();
        }
        bool Owned(int n)=>PlayerPrefs.GetInt(SaveKey+"decor."+n,0)==1;
        void Bonuses(){model.patienceMultiplier=Owned(0)?1.05f:1;model.tipMultiplier=Owned(1)?1.05f:1;model.brewSpeed=Owned(2)?1.05f:1;}
        void ResetDay(){model=new TavernModel{started=true,tipRemainder=PlayerPrefs.GetFloat(SaveKey+"tipRemainder",0)};Bonuses();foreach(var g in TavernModel.Guests)if(PlayerPrefs.GetInt("sunflower.codex."+g.id,0)==1)model.codex.Add(g.id);arrivals.Clear();arrivalTime=0;servicePulse=0;tutorialEnabled=PlayerPrefs.GetInt(SaveKey+"tutorialDone",0)==0;tutorialBaseline=0;tutorialCompleteTime=0;for(int i=1;i<8;i++){visualVisits[i]=-1;guestVisibility[i]=0;guests[i].gameObject.SetActive(false);}focusPaused=false;Close();}
        bool CanUseGameplayInput()=>model!=null&&!model.paused&&!model.ended&&!focusPaused&&modal==null&&Time.frameCount>inputBlockedFrame;
        void Turn(int delta){if(CanUseGameplayInput())model.Turn(delta);}
        void Select(int n){if(!CanUseGameplayInput())return;if(model.direction==n)Interact();else model.direction=n;}
        void Interact(){if(!CanUseGameplayInput())return;var v=model.At(model.direction);if(v!=null&&v.state==VisitState.Order){Dialogue(v);return;}bool delivered=v!=null&&v.state==VisitState.Waiting&&model.hand!=null&&model.hand.owner==v.id;model.Interact();if(delivered){servicePulse=.32f;serviceDirection=model.direction;}}
        void Update()
        {
            if(model==null)return;
            if(Input.GetKeyDown(KeyCode.Escape)){if(modal!=null)Close();else Pause();}
            if(CanUseGameplayInput()){if(Input.GetKeyDown(KeyCode.LeftArrow))model.Turn(-1);if(Input.GetKeyDown(KeyCode.RightArrow))model.Turn(1);if(Input.GetKeyDown(KeyCode.Space))Interact();}
            model.Update(Time.deltaTime);
            if(!model.paused){arrivalTime-=Time.deltaTime;foreach(var v in model.visitors)if(arrivals.Add(v.id)){toast.text="客人入场 · "+v.guest.name;arrivalTime=3;}}
            arrivalCard.SetActive(arrivalTime>0);
            foreach(var id in model.codex)if(PlayerPrefs.GetInt("sunflower.codex."+id,0)==0){PlayerPrefs.SetInt("sunflower.codex."+id,1);PlayerPrefs.Save();}
            if(model.TryClaimSettlement(out int income)){wallet+=income;PlayerPrefs.SetInt(SaveKey+"wallet",wallet);PlayerPrefs.SetFloat(SaveKey+"tipRemainder",model.tipRemainder);PlayerPrefs.Save();Settlement();}
            hud.text="南风岛 · 第1天       今日 "+model.coins+" / 70       钱包 "+wallet+"       "+Mathf.CeilToInt(120-model.elapsed)+" 秒";
            status.text=model.message;
            if(model.hand!=null){var owner=model.visitors.Find(v=>v.id==model.hand.owner);queue.text="手持："+model.hand.drink+" → P"+(owner==null?"?":owner.seat.ToString());}
            else queue.text=model.ready!=null?"已做好："+model.ready.drink+" · 面向出酒口取杯":model.queue.Count>0?"制作："+model.queue[0].drink+"  "+model.queue[0].remaining.ToString("0.0")+"s  | 排队 "+model.queue.Count:"点击客位转向，再次点击互动";
            RefreshCharacterMotion(model.paused||model.ended||focusPaused?0:Time.deltaTime);
            RefreshActionHint();
            int tutorialTarget=RefreshTutorial();
            for(int i=0;i<8;i++)
            {
                faces[i].color=tutorialTarget==i?new Color(.55f,.9f,.55f):model.direction==i?new Color(1,.65f,.12f):new Color(1,.94f,.75f);
                if(i==0){labels[i].text=model.ready==null?"出酒口":"出酒口 · 取杯";continue;}
                var v=model.At(i);guestHits[i].SetActive(v!=null);bars[i].transform.parent.gameObject.SetActive(v!=null&&(v.state==VisitState.Order||v.state==VisitState.Waiting));
                if(v==null){labels[i].text="P"+i+" · "+(model.Blocked(i)?"行李占座":"空位");continue;}
                SetGuest(guests[i],v.guest);
                labels[i].text="P"+i+" · "+v.guest.name.Split(' ')[0]+"\n"+(v.state==VisitState.Order?"点单":v.state==VisitState.Waiting?(v.guest.id=="horn"&&v.bubble<=0?"再问一次":v.guest.drink):v.state==VisitState.Drinking?"饮用中":"收钱 "+Mathf.CeilToInt(v.timer));
                var r=bars[i].rectTransform;r.pivot=new Vector2(0,.5f);r.anchoredPosition=new Vector2(0,3.5f);r.sizeDelta=new Vector2(145*Mathf.Clamp01(v.patience/(25*model.patienceMultiplier)),7);
            }
        }
        int RefreshTutorial()
        {
            tutorialCard.SetActive(tutorialEnabled&&!model.ended&&modal==null);
            if(!tutorialEnabled||model.ended)return -1;
            if(model.served>tutorialBaseline)
            {
                if(PlayerPrefs.GetInt(SaveKey+"tutorialDone",0)==0){PlayerPrefs.SetInt(SaveKey+"tutorialDone",1);PlayerPrefs.Save();}
                tutorialLabel.text="完成！接单 → 取杯 → 送达 → 收钱。继续招呼下一位吧！";
                if(!model.paused&&!focusPaused)tutorialCompleteTime+=Time.deltaTime;
                if(tutorialCompleteTime>=3){tutorialEnabled=false;tutorialCard.SetActive(false);}
                return -1;
            }
            tutorialLabel.text=model.ServiceHint(out int target);
            return target;
        }
        void RefreshCharacterMotion(float dt)
        {
            // Presentation only: never delay orders, payouts, or seat release.
            servicePulse=Mathf.Max(0,servicePulse-dt);
            float pulse=servicePulse>0?Mathf.Sin((1-servicePulse/.32f)*Mathf.PI):0;
            Vector2 reach=(seats[serviceDirection]-new Vector2(800,465)).normalized;
            sunny.rectTransform.anchoredPosition=new Vector2(800,465)+reach*(8*pulse);
            sunny.rectTransform.localScale=new Vector3(model.direction>4?-1:1,1,1)*(1+.035f*pulse);
            for(int i=1;i<8;i++)
            {
                var visit=model.At(i);
                if(visit!=null&&visualVisits[i]!=visit.id){visualVisits[i]=visit.id;guestVisibility[i]=0;SetGuest(guests[i],visit.guest);}
                guestVisibility[i]=Mathf.MoveTowards(guestVisibility[i],visit==null?0:1,dt/.22f);
                float alpha=guestVisibility[i];
                guests[i].color=new Color(1,1,1,alpha);
                guests[i].rectTransform.anchoredPosition=seats[i]+new Vector2(-30,35-10*(1-alpha));
                guests[i].gameObject.SetActive(alpha>0);
                if(visit==null&&alpha==0)visualVisits[i]=-1;
            }
        }
        void RefreshActionHint()
        {
            var v=model.At(model.direction);
            selectionLabel.text=model.direction==0?"面向：出酒口":"面向：P"+model.direction+" · "+(v==null?(model.Blocked(model.direction)?"行李占座":"空位"):v.guest.name.Split(' ')[0]);
            // Hints describe the existing interaction; wrong-cup delivery stays possible.
            bool actionable=true;
            if(model.direction==0){actionLabel.text=model.hand!=null?"先送饮品":model.ready!=null?"取杯":"制作中";actionable=model.hand==null&&model.ready!=null;if(model.hand==null&&model.ready==null&&model.queue.Count==0)actionLabel.text="先接单";}
            else if(v==null){actionLabel.text="暂无客人";actionable=false;}
            else if(v.state==VisitState.Order)actionLabel.text="接单";
            else if(v.state==VisitState.Waiting)actionLabel.text=model.hand!=null?"送达":"问订单";
            else if(v.state==VisitState.Payment)actionLabel.text="收钱";
            else{actionLabel.text="饮用中";actionable=false;}
            actionButton.interactable=CanUseGameplayInput()&&actionable;
        }
        void Welcome(){Open("南风岛 · 准备营业");Label(modal.transform,new Vector2(800,470),new Vector2(760,180),"120 秒内赚到 70 金币\n接单 → 出酒口取杯 → 送达 → 收钱\n点击转向，再次点击互动；也可用方向键和空格",26);MakeButton(modal.transform,new Vector2(800,310),new Vector2(300,70),"开始营业",Close);}
        void Pause(){if(model.ended){Settlement();return;}Open("休息一下");MakeButton(modal.transform,new Vector2(800,470),new Vector2(300,70),"继续营业",Close);MakeButton(modal.transform,new Vector2(800,360),new Vector2(300,65),tutorialEnabled?"关闭教学提示":"重新开启教学",()=>{tutorialEnabled=!tutorialEnabled;tutorialBaseline=model.served;tutorialCompleteTime=0;Close();});}
        void Dialogue(Visit v){Open(v.guest.name);var a=Art(modal.transform,new Vector2(520,465),new Vector2(230,230),"Bobo_Portrait");SetGuest(a,v.guest);Label(modal.transform,new Vector2(940,485),new Vector2(470,190),v.guest.bio+"\n\n来一杯"+v.guest.drink+"！",25);MakeButton(modal.transform,new Vector2(940,310),new Vector2(300,65),"马上来！",()=>{Close();model.direction=v.seat;model.Interact();});}
        void Codex(int selected)
        {
            Open("客人图鉴",true);
            for(int i=0;i<9;i++){int n=i;bool known=i<TavernModel.Guests.Length&&model.codex.Contains(TavernModel.Guests[i].id);MakeButton(modal.transform,new Vector2(420+(i%3)*150,580-(i/3)*125),new Vector2(135,100),known?TavernModel.Guests[i].name.Split(' ')[0]:"未遇见",()=>{if(known)Codex(n);});}
            var g=TavernModel.Guests[Mathf.Clamp(selected,0,2)];bool unlocked=model.codex.Contains(g.id);
            if(unlocked){var a=Art(modal.transform,new Vector2(1060,510),new Vector2(230,230),"Bobo_Portrait");SetGuest(a,g);}
            Label(modal.transform,new Vector2(1060,670),new Vector2(440,60),unlocked?g.name:"未知客人",25);
            Label(modal.transform,new Vector2(1060,295),new Vector2(420,165),unlocked?g.bio+"\n喜欢："+g.drink:"完成服务并收钱，解锁人物小传。\n更多客人将在后续营业日登场。",23);
        }
        void Settlement(){Open(model.Passed?"今日打烊 · 目标达成":"今日打烊 · 明天再试");Label(modal.transform,new Vector2(800,490),new Vector2(720,170),"营业收入  "+model.coins+"\n服务客人  "+model.served+"     图鉴  "+model.codex.Count+" / 9\n金币已入账 · 钱包 "+wallet,29);MakeButton(modal.transform,new Vector2(620,310),new Vector2(280,65),"装饰酒馆",Shop);MakeButton(modal.transform,new Vector2(960,310),new Vector2(280,65),"重玩第1天",ResetDay);}
        void Shop()
        {
            Open("装饰酒馆 · 钱包 "+wallet);bool allowed=model.elapsed==0||model.ended;
            for(int i=0;i<3;i++){int n=i;float x=510+i*290;Label(modal.transform,new Vector2(x,495),new Vector2(270,150),items[i]+"\n"+effects[i]+"\n"+prices[i]+" 金币",23);var b=MakeButton(modal.transform,new Vector2(x,340),new Vector2(240,65),Owned(i)?"已拥有":allowed?"购买":"打烊后购买",()=>{if(Owned(n)||wallet<prices[n]||!allowed)return;wallet-=prices[n];PlayerPrefs.SetInt(SaveKey+"wallet",wallet);PlayerPrefs.SetInt(SaveKey+"decor."+n,1);PlayerPrefs.Save();if(model.elapsed==0)Bonuses();Shop();});b.interactable=allowed&&!Owned(i)&&wallet>=prices[i];}
        }
        void Open(string title,bool book=false){Close();model.paused=true;modal=Solid(root,new Vector2(800,450),new Vector2(1600,900),new Color(0,0,0,.55f));modal.name="Modal";if(book)Art(modal.transform,new Vector2(800,450),new Vector2(1250,690),"Codex_Book");else Card(modal.transform,new Vector2(800,450),new Vector2(1100,600));Label(modal.transform,new Vector2(800,book?745:660),new Vector2(950,70),title,32);MakeButton(modal.transform,new Vector2(1330,book?745:660),new Vector2(70,55),"×",Close);}
        void Close(){if(modal!=null){inputBlockedFrame=Time.frameCount;modal.SetActive(false);Destroy(modal);modal=null;}if(model!=null)model.paused=focusPaused;}
        void OnApplicationFocus(bool focus){if(!focus&&model!=null&&!model.ended){focusPaused=true;Pause();}else if(focus&&focusPaused){focusPaused=false;if(model!=null)model.paused=modal!=null;}}
        static GameObject Node(string name,Transform parent,Vector2 p,Vector2 size){var go=new GameObject(name,typeof(RectTransform));go.transform.SetParent(parent,false);var r=go.GetComponent<RectTransform>();r.anchorMin=r.anchorMax=Vector2.zero;r.pivot=new Vector2(.5f,.5f);r.anchoredPosition=p;r.sizeDelta=size;return go;}
        GameObject Solid(Transform parent,Vector2 p,Vector2 size,Color color){var go=Node("Panel",parent,p,size);go.AddComponent<Image>().color=color;return go;}
        GameObject Card(Transform parent,Vector2 p,Vector2 size){var go=Node("Card",parent,p,size);var im=go.AddComponent<Image>();im.sprite=Slice("Dialogue_Panel");im.type=Image.Type.Sliced;im.raycastTarget=false;return go;}
        Sprite Slice(string asset){if(!sprites.ContainsKey(asset)){var rect=asset=="Button_Gold"?new Rect(136,156,1900,419):new Rect(35,146,2103,416);sprites[asset]=Sprite.Create(Texture(asset),rect,new Vector2(.5f,.5f),100,0,SpriteMeshType.FullRect,new Vector4(160,110,160,110));}return sprites[asset];}
        Texture2D Texture(string name){if(!textures.ContainsKey(name)){textures[name]=Resources.Load<Texture2D>("IslandUI/"+name);if(textures[name]==null)Debug.LogError("Missing island art: "+name);}return textures[name];}
        RawImage Art(Transform parent,Vector2 p,Vector2 size,string asset){var a=Node(asset,parent,p,size).AddComponent<RawImage>();a.texture=Texture(asset);a.raycastTarget=false;return a;}
        void SetGuest(RawImage a,GuestDefinition g){if(g.id=="horn"){a.texture=hornPortrait!=null?hornPortrait:hornFallback;a.uvRect=hornPortrait!=null?new Rect(0,0,1,1):new Rect(.515f,.285f,.16f,.47f);}else{a.texture=Texture(g.id=="bobo"?"Bobo_Portrait":"Coco_Portrait");a.uvRect=new Rect(0,0,1,1);}}
        Text Label(Transform parent,Vector2 p,Vector2 size,string value,int fontSize){var t=Node("Text",parent,p,size).AddComponent<Text>();t.font=font;t.text=value;t.fontSize=fontSize;t.color=new Color(.25f,.12f,.05f);t.alignment=TextAnchor.MiddleCenter;t.raycastTarget=false;return t;}
        Button MakeButton(Transform parent,Vector2 p,Vector2 size,string value,Action action){var go=Solid(parent,p,size,Color.white);var im=go.GetComponent<Image>();im.sprite=Slice("Button_Gold");im.type=Image.Type.Sliced;var b=go.AddComponent<Button>();b.onClick.AddListener(()=>action());Label(go.transform,size/2,size-Vector2.one*12,value,20);return b;}
        void OnDestroy(){foreach(var sprite in sprites.Values)if(sprite!=null)Destroy(sprite);if(root!=null)Destroy(root.parent.gameObject);}
    }
}
