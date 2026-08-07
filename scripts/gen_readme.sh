#!/usr/bin/env bash
set -euo pipefail
OWNER="${OWNER:-SINGHL25}"; OUT="${OUT:-README.md}"; TOPN="${TOPN:-6}"; SHOW_PRIVATE="${SHOW_PRIVATE:-0}"
DATA="$(gh repo list "$OWNER" --no-archived --limit 1000 \
  --json name,description,primaryLanguage,stargazerCount,repositoryTopics,visibility \
  --jq '.[] | [([ (.repositoryTopics//[])[] | if type=="object" then .name else . end ]|join(";")),
      (.stargazerCount//0|tostring), .name, (.primaryLanguage.name//"—"),
      (.visibility|ascii_upcase), ((.description//"")|gsub("[\t\n\r]";" "))] | @tsv')"
[ -z "$DATA" ] && { echo "ERROR: gh returned 0 repos — check 'gh auth status'." >&2; exit 1; }
TRACKS=$(cat <<'CFG'
its-tolling	🛣️	ITS & Tolling Systems	1f6feb	ITS_%26_Tolling_Systems	Tolling infra, gantries, cameras, C-ITS, tunnels — production-scale traffic systems.	its--tolling-systems
smart-mobility	🚦	Smart Mobility & Traffic	2da44e	Smart_Mobility_%26_Traffic	Traffic monitoring, EV routing, GNSS, vehicle telematics.	smart-mobility--traffic
ai-ml	🤖	AI, ML & Deep Learning	8250df	AI,_ML_%26_Deep_Learning	Transformers, LSTMs, CNNs, diffusion, applied ML demos.	ai-ml--deep-learning
algo-trading	📈	Algo Trading & Fintech	bf8700	Algo_Trading_%26_Fintech	MCX/Zerodha strategies, backtesting, quant dashboards.	algo-trading--fintech
data-analytics	📊	Data & Dashboards	d4351c	Data_%26_Dashboards	SQL, Power BI, Grafana, EDA, BI dashboards.	data--dashboards
devops-cloud	☁️	DevOps, Cloud & APIs	0969da	DevOps,_Cloud_%26_APIs	Kubernetes, Docker, observability, backend APIs.	devops-cloud--apis
web-apps	🌐	Web & Mobile Apps	1a7f37	Web_%26_Mobile_Apps	Full-stack web + mobile apps in Flutter, React, JS.	web--mobile-apps
learning-lab	🧪	Learning Playgrounds	6e7781	Learning_Playgrounds	Interactive notebooks and hands-on tutorials.	learning-playgrounds
CFG
)
TOTAL=$(printf '%s\n' "$DATA" | grep -c .)
PUB=$(printf '%s\n' "$DATA" | awk -F'\t' '$5=="PUBLIC"{c++}END{print c+0}')
count_track(){ printf '%s\n' "$DATA" | awk -F'\t' -v k="$1" '{n=split($1,a,";");for(i=1;i<=n;i++)if(a[i]==k){c++;break}}END{print c+0}'; }
CATEGORIZED=$(printf '%s\n' "$DATA" | awk -F'\t' 'BEGIN{split("its-tolling smart-mobility ai-ml algo-trading data-analytics devops-cloud web-apps learning-lab",K," ")}{n=split($1,a,";");for(i=1;i<=n;i++){for(j in K)if(a[i]==K[j]){c++;f=1;break}if(f){f=0;break}}}END{print c+0}')
MISC=$(( TOTAL - CATEGORIZED )); if (( MISC < 0 )); then MISC=0; fi
row_for_track(){ local key="$1" i=0
  printf '%s\n' "$DATA" | awk -F'\t' -v k="$key" -v sp="$SHOW_PRIVATE" '{n=split($1,a,";");hit=0;for(x=1;x<=n;x++)if(a[x]==k)hit=1; if(hit && (sp=="1" || $5=="PUBLIC")) print}' \
    | sort -t$'\t' -k2,2nr -k3,3 | head -n "$TOPN" \
    | while IFS=$'\t' read -r topics stars name lang vis desc; do i=$((i+1))
        desc="${desc//|//}"; [ ${#desc} -gt 62 ] && desc="${desc:0:61}…"; [ -z "$desc" ] && desc="_(description coming)_"
        tag=""; [ "$vis" != "PUBLIC" ] && tag=" 🔒"
        printf '| %d | **[%s](https://github.com/%s/%s)**%s | %s | `%s` | %s |\n' "$i" "$name" "$OWNER" "$name" "$tag" "$desc" "$lang" "$stars"
      done
}
{
cat <<HEADER
# 👋 Hi, I'm Akhilesh Kumar Singh

### ITS Engineer @ Kapsch · Building ML‑powered Smart Mobility systems

\`Python\` · \`TypeScript\` · \`TensorFlow\` · \`Power BI\` · \`Docker\` · \`Kubernetes\` · \`Streamlit\`

📍 Brisbane, Australia &nbsp;·&nbsp; 📧 [akhi.singh1989@gmail.com](mailto:akhi.singh1989@gmail.com) &nbsp;·&nbsp; [LinkedIn](https://www.linkedin.com/in/akhilesh-kumar-singh-23115836) &nbsp;·&nbsp; [Kaggle](https://www.kaggle.com/singhl25) &nbsp;·&nbsp; [Topmate](https://topmate.io/akhilesh_kumar52/)

---

## 📊 Portfolio at a glance

**${TOTAL}** total repos across **8 tracks** · ${CATEGORIZED} categorized · ${MISC} untagged &nbsp;·&nbsp; ${PUB} public

## 🗂️ Filter by track

> Every categorized repo carries a GitHub **topic tag**. Click a badge to open the live filtered list.

<p align='left'>
HEADER
while IFS=$'\t' read -r key emoji name color label blurb anchor; do [ -z "$key" ] && continue
  printf '<a href="https://github.com/%s?tab=repositories&q=topic%%3A%s"><img src="https://img.shields.io/badge/%s-%s?style=for-the-badge" alt="%s"/></a>\n' "$OWNER" "$key" "$label" "$color" "$name"
done <<< "$TRACKS"
echo "</p>"; echo ""; echo "---"; echo ""; echo "## 🧭 Jump to a section"; echo ""
jump=""; while IFS=$'\t' read -r key emoji name color label blurb anchor; do [ -z "$key" ] && continue
  n=$(count_track "$key"); seg="$emoji [$name ($n)](#$anchor)"; jump="${jump:+$jump &nbsp;·&nbsp; }$seg"
done <<< "$TRACKS"; echo "$jump"; echo ""; echo "---"
while IFS=$'\t' read -r key emoji name color label blurb anchor; do [ -z "$key" ] && continue
  n=$(count_track "$key")
  echo ""; echo "### $emoji $name"; echo ""
  echo "[<img src='https://img.shields.io/badge/${n}_repos-${color}?style=flat-square' alt='${n} repos'/>](https://github.com/$OWNER?tab=repositories&q=topic%3A$key) &nbsp; _${blurb}_"
  echo ""; echo "| # | Repository | What it does | Stack | ⭐ |"; echo "|---|---|---|---|---|"
  row_for_track "$key"
  echo ""; echo "<sub>🔎 **[Browse all $n $name repos →](https://github.com/$OWNER?tab=repositories&q=topic%3A$key)**</sub>"
  echo ""; echo "---"
done <<< "$TRACKS"
cat <<'FOOTER'

## 🛠️ Core Stack

![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white) ![TypeScript](https://img.shields.io/badge/TypeScript-3178C6?style=for-the-badge&logo=typescript&logoColor=white) ![TensorFlow](https://img.shields.io/badge/TensorFlow-FF6F00?style=for-the-badge&logo=tensorflow&logoColor=white) ![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white) ![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white) ![Streamlit](https://img.shields.io/badge/Streamlit-FF4B4B?style=for-the-badge&logo=streamlit&logoColor=white)

## 📊 GitHub Stats

<a href="https://github.com/SINGHL25"><img src="https://github-readme-stats.vercel.app/api?username=SINGHL25&show_icons=true&theme=tokyonight" height="160"/></a> <a href="https://github.com/SINGHL25"><img src="https://github-readme-stats.vercel.app/api/top-langs/?username=SINGHL25&layout=compact&theme=tokyonight" height="160"/></a>

---

<sub>⚡ Auto-generated from live GitHub topics — counts, badges, and links always in sync. 🔒 = private repo.</sub>
FOOTER
} > "$OUT"
echo "WROTE $OUT | total=$TOTAL ($PUB public) categorized=$CATEGORIZED untagged=$MISC" >&2
