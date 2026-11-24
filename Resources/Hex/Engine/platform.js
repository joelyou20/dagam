'use strict';
/* Standard-only host adapter. No points, app globals, purchases or online services. */
const HEX_DAILY_ROUND_LIMIT=60;
const hexId=n=>'LT-'+String(n).padStart(3,'0');
const hexBaseId=id=>HEX_CARD[id]?.baseId||id;
const hexDailyHas=()=>false;
const hexDailyBase=(g,c)=>({attack:hexDef(c).attack,hp:Math.max(1,c.baseHp||hexDef(c).hp)});
const hexDailyQueueEcho=()=>{};
const hexDailyReactionEcho=()=>{};
const hexDailyValidEcho=()=>false;
const hexModeFormat=()=> 'standard';
function hexCanUseQuicken(g,p,t){if(!t||g.phase!=='pre'||g.active!==p||t.owner!==p||t.playedTurn!==g.turn||hexRuntimeKeyword(g,t,'sprint')||!hexLegalTargets(g,t).length)return false;return hexReady(g,{...t,grants:[...(t.grants||[]),{id:'sprint',until:g.turn}]});}
