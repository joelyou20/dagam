'use strict';
/* First Light's 64 authored cards. Trigger jobs, choices and response frames are saved as data. */
function hexProtectedFromSpecial(g,c){return c.slot>=hexColumns(g)&&g.players[c.owner].board[c.slot-hexColumns(g)]&&hexNum(g.players[c.owner].board[c.slot-hexColumns(g)])===51;}
function hexVisualCard(c){return c?{uid:c.uid,id:c.id,owner:c.owner,slot:c.slot??null}:null;}
const hexWardRemaining=c=>Math.max(0,Number.isFinite(c.wardRemaining)?c.wardRemaining:hexKeyword(c,'ward')-(c.wardTurn!=null?1:0));
function hexAffect(g,owner,target,fn,special=false,source=g.effectSource,harmful=owner!==target?.owner){
 if(!target||target.invisibleUntil!=null&&!g.untargeted||special&&!hexSpellTargetable(target))return false;if(owner!==target.owner&&special&&hexProtectedFromSpecial(g,target))return false;
 if(harmful&&hexWardRemaining(target)>0){target.wardRemaining=hexWardRemaining(target)-1;delete target.wardTurn;hexVisualEvent(g,'ward',{source:hexVisualCard(source),target:hexVisualCard(target),remaining:target.wardRemaining});hexLog(g,hexName(target)+' · Ward prevented an effect · '+target.wardRemaining+' remaining.');return false;}
 fn();return true;
}
function hexDamage(g,hits){return hexWithVisualBatch(g,()=>hexDamageBatch(g,hits));}
function hexDamageBatch(g,hits){
 hits=hexElderSplit(g,hits);const events=[],reflections=[];
 for(const hit of hits){const target=hexFind(g,hit.target);if(!target||target.hp<=0)continue;if(!hexElderCanHit(g,hit,target))continue;if(hit.source&&hexRuntimeKeyword(g,hit.source,'penetrate'))hit.ignoreShield=true;let n=Math.max(0,hit.amount),eq=target.eq?hexNum(target.eq):0;
 if(hexNum(target)===24&&target.hp<=Math.floor(target.maxHp/2))n--;
 if(target.amberUntil>=g.turn&&target.stunUntil>=g.turn)n--;
 if(g.field&&hexElderNum(target.eq)!==33&&hexNum(g.field)===60&&target.slot>=hexColumns(g)&&g.players[target.owner].board[target.slot-hexColumns(g)])n--;
 if(n>0&&eq===23&&hit.special&&target.veilTurn!==g.turn){target.veilTurn=g.turn;n--;}
 if(n>0&&eq===56&&hit.artifact&&target.gripTurn!==g.turn){target.gripTurn=g.turn;n--;}
 if(n>0&&eq===61&&g.active!==target.owner&&target.pearlTurn!==g.turn){target.pearlTurn=g.turn;n--;}
 n=Math.max(0,n);const absorbed=hit.ignoreShield?0:Math.min(n,target.shield||0);target.shield=Math.max(0,(target.shield||0)-absorbed);target.winterShield=Math.max(0,(target.winterShield||0)-absorbed);n-=absorbed;if(absorbed&&(target.reflectUntil>=g.turn||hexRuntimeKeyword(g,target,'reflect'))&&hit.source?.uid&&!hit.reflected)reflections.push({target:hit.source.uid,amount:absorbed,source:{...target},reflected:true});const actual=Math.min(target.hp,n);target.hp-=n;if(absorbed&&target.tempShield)target.tempShield=Math.max(0,target.tempShield-absorbed);if(hit.combat&&actual&&hexElderNum(target)===7)target.gold=(target.gold||0)+1;if(hit.combat&&!actual&&hexElderNum(hit.source)===14){const ram=hexFind(g,hit.source.uid);if(ram)hexStun(g,ram);}
 if(!hit.combat&&(actual||absorbed))hexVisualEvent(g,'damage',{source:hexVisualCard(hit.source),target:hexVisualCard(target),amount:actual,absorbed});
 if(actual){target.lastSource=hit.source?.uid;target.lastCombat=!!hit.combat;events.push({...hit,target:target.uid,actual,targetSnapshot:{...target}});}
 }
 // Lethal prevention is checked after the whole simultaneous damage batch.
 for(const c of hexAll(g))if(c.hp<=0&&(hexKeyword(c,'resilient')||hexElderKeyword(g,c,'resilient'))&&!c.spent.resilient&&!c.spent.lich){c.spent.resilient=true;c.hp=1;hexLog(g,hexName(c)+' · Resilient survives at 1 HP.');}
 const deaths=hexDeaths(g);if(g.winner!==null)return events;
 for(const e of events.slice().reverse())if(e.combat)g.tasks.unshift({kind:'combatHit',...e});
 for(const dead of deaths)hexDeathTriggers(g,dead);
 for(const e of events)if(!e.combat)hexArcanaHit(g,e);
 if(reflections.length&&g.winner===null)hexDamage(g,reflections);
 return events;
}
function hexDeaths(g){
 // Board positions are authoritative: older saved instances can have stale slot metadata.
 g.elderDeathObservers=hexAll(g).filter(c=>hexElderNum(c)===45).map(c=>({...c}));g.arcanaDeathObservers=hexAll(g).filter(c=>hexArcanaNum(c)===44).map(c=>c.owner);
 const entries=g.players.flatMap((p,owner)=>p.board.flatMap((c,slot)=>c&&c.hp<=0?[{c,p,owner,slot}]:[])),dead=entries.map(e=>e.c);if(!dead.length)return [];
 for(const {c,p,owner,slot} of entries){c.owner=owner;c.slot=slot;hexVisualEvent(g,'destroy',hexVisualCard(c));p.board[slot]=null;const counts=!hexHasType(c,'Summon');if(counts)p.losses++;c.elderFallenEquipment=c.eq;if(c.eq)p.discard.push(c.eq);c.eq=null;if(counts)g.players[hexOriginalOwner(c,owner)].discard.push(c);else hexRemoveFromGame(g,c);hexLog(g,hexName(c)+' fell · '+(counts?hexOwnerLabel(c.owner)+' lost '+p.losses+'/'+hexRules(g).losses:'Summon · defeat count unchanged ('+p.losses+'/'+hexRules(g).losses+')')+'.');}
 hexElderExile(g);const losers=g.players.map((p,i)=>p.losses>=hexRules(g).losses?i:null).filter(i=>i!==null);if(losers.length){g.winner=losers.length===2?-1:1-losers[0];g.phase='over';g.tasks=[];g.stack=[];g.choice=null;return dead;}
 for(const c of dead)hexQueueEvent(g,{kind:'death',actor:1-c.owner,owner:c.owner,dead:c.uid});
 return dead;
}
function hexDeathTriggers(g,c){
 hexArcanaDeath(g,c);hexElderDeath(g,c);const n=hexNum(c),pl=g.players[c.owner];
 if(n===7&&!c.spent.ash){c.spent.ash=true;c.baseHp=3;(g.ashReturns||(g.ashReturns=[])).push({owner:c.owner,uid:c.uid});}
 if(n===8)g.tasks.unshift({kind:'blast',owner:c.owner,targets:g.players[1-c.owner].board.filter(Boolean).map(t=>t.uid),amount:1,source:c});
 if(hexKeyword(c,'deathburst')&&c.lastSource)g.tasks.unshift({kind:'abilityDamage',owner:c.owner,target:c.lastSource,amount:hexKeyword(c,'deathburst'),source:c});
 for(const ally of pl.board.filter(a=>a&&hexKeyword(a,'packbond')&&hexBaseId(a.id)===hexBaseId(c.id)))ally.attackBonus=(ally.attackBonus||0)+1;
 if(c.slot<hexColumns(g)){const behind=pl.board[c.slot+hexColumns(g)];if(behind&&hexNum(behind)===15)hexStun(g,behind);}
}
function hexAbilityDamage(g,p,target,amount,source,extra={}){if(extra.special&&source&&hexType(source,'Spell'))amount+=g.players[p].artifacts.filter(c=>c&&hexArcanaNum(c)===33).length;return hexAffect(g,p,hexFind(g,target),()=>hexDamage(g,[{target,source,amount,...extra,wardChecked:true}]),!!extra.special,source,true);}
function hexSwap(g,p,a,b){const pl=g.players[p],x=pl.board[a],y=pl.board[b];if(!x||!y)return false;if(p!==g.active&&[x,y].some(c=>c.eq&&hexNum(c.eq)===38))return false;[pl.board[a],pl.board[b]]=[y,x];x.slot=b;y.slot=a;return true;}
function hexRemoveFromGame(g,c){const owner=hexOriginalOwner(c),pile=g.players[owner].exile||(g.players[owner].exile=[]);if(!pile.some(t=>t.uid===c.uid))pile.push(c);}
function hexReturn(g,c){if(!c)return;const summon=hexHasType(c,'Summon');hexVisualEvent(g,summon?'destroy':'return',hexVisualCard(c));const p=g.players[c.owner];p.board[c.slot]=null;if(c.eq)p.discard.push(c.eq);c.eq=null;if(summon){hexRemoveFromGame(g,c);hexLog(g,hexName(c)+' left the battlefield · Summon removed from the game.');}else{hexResetInstance(c);p.hand.push(c);hexLog(g,hexName(c)+' returned to hand.');}hexElderExile(g);}

function hexResetInstance(c){for(const k of ['hp','maxHp','slot','shield','attackBonus','mods','stunUntil','burn','scars','fuses','charge','amberUntil','noShieldUntil','playedTurn','playedOwnerTurn','wardTurn','wardRemaining','pearlTurn','gripTurn','veilTurn','crownTurn','mouseTurn','lastCombat','lastSource','winterShield','spearTurn','raiseTurn','silkTurn','grants','tauntUntil','reflectUntil','control','sacrificeAtEnd','pebbles','pebbleTurn','gold','channel','invisibleUntil','zeroAttackUntil','tempShield','tempShieldUntil','enraptureDue','elderFallenEquipment'])delete c[k];}
function hexCombat(g,attackId=null){
 const hits=[],visuals=[];g.combatParticipants=g.combatParticipants||[];
 for(const attack of g.attacks){if(attack.resolved||(attackId&&attack.id!==attackId))continue;attack.resolved=true;const a=hexFind(g,attack.attacker),t=hexFind(g,attack.target);if(attack.canceled||!a||!t||!hexLegalTargets(g,a).some(c=>c.uid===t.uid))continue;
 let power=hexStats(g,a).attack;if(hexNum(a)===14&&t.hp<t.maxHp)power++;if(hexNum(a)===26&&t.stunUntil>=g.turn)power+=2;
 if(a.eq&&hexNum(a.eq)===34&&hexHasType(t,'Undead'))power++;if(a.eq&&hexNum(a.eq)===40&&t.slot>=hexColumns(g))power=Math.max(0,power-1);
 if(g.field&&hexElderNum(a.eq)!==33&&hexNum(g.field)===48&&a.slot<hexColumns(g)&&hexHasType(t,'Dragon'))power++;
 power+=attack.chargeBonus||0;
 visuals.push({attacker:a.uid,defender:t.uid,attackerId:a.id,defenderId:t.id,owner:a.owner,attackerSlot:a.slot,defenderSlot:t.slot});hits.push({source:{...a},target:t.uid,amount:power,combat:true,ignoreShield:!!hexRuntimeKeyword(g,a,'penetrate')},{source:{...t},target:a.uid,amount:hexStats(g,t).attack,combat:true,ignoreShield:!!hexRuntimeKeyword(g,t,'penetrate')});g.combatParticipants.push(a.uid);if(hexRuntimeKeyword(g,a,'follow-up')&&!attack.follow)g.tasks.push(hexElderTask(a.owner,'follow',{attacker:a.uid,target:t.uid}));
 }
 hexLog(g,'Combat resolves · '+visuals.length+' attack'+(visuals.length===1?'':'s')+'.');const queued=visuals.map(v=>hexVisualEvent(g,'attack',v));const damage=hexDamage(g,hits);for(const v of queued){v.damage=damage.filter(e=>e.source?.uid===v.attacker&&e.target===v.defender).reduce((n,e)=>n+e.actual,0);v.retaliation=damage.filter(e=>e.source?.uid===v.defender&&e.target===v.attacker).reduce((n,e)=>n+e.actual,0);}
}
function hexCombatHit(g,e){
 const source=e.source;if(!source)return;hexArcanaHit(g,e);hexElderHit(g,e);const n=hexNum(source),target=hexFind(g,e.target),aliveSource=hexFind(g,source.uid),eq=source.eq?hexNum(source.eq):0;
 if(target&&hexKeyword(source,'stunning'))hexAffect(g,source.owner,target,()=>{hexStun(g,target);if(n===2)target.amberUntil=target.stunUntil;});
 if(target&&n===11)hexAffect(g,source.owner,target,()=>hexBuff(g,target,-1,hexNextOwnerEnd(g,target.owner)));
 if(target&&hexKeyword(source,'scorch'))hexAffect(g,source.owner,target,()=>{if(!(target.eq&&hexNum(target.eq)===53))target.burn={due:g.players[target.owner].turns+1};});
 if(target&&n===20&&target.slot>=hexColumns(g))hexAsk(g,source.owner,'Return '+hexName(target)+' to hand?',[{label:'Return '+hexName(target),task:{kind:'returnEnemy',owner:source.owner,target:target.uid}}],true);
 if(target&&n===30)hexAffect(g,source.owner,target,()=>{target.scars=(target.scars||0)+1;});
 if(target&&n===32)hexAffect(g,source.owner,target,()=>{target.fuses=(target.fuses||0)+1;if(target.fuses>=2){target.fuses=0;g.tasks.unshift({kind:'abilityDamage',owner:source.owner,target:target.uid,amount:3,source});}});
 if(n===22&&aliveSource&&e.targetSnapshot.slot>=hexColumns(g))hexHeal(g,aliveSource,1);
 if(target&&hexNum(target)===6&&target.mouseTurn!==g.turn){target.mouseTurn=g.turn;target.attackBonus=(target.attackBonus||0)+1;}
 if(target){for(const artifact of g.players[target.owner].artifacts.filter(c=>c&&hexNum(c)===31))if(artifact.rootTurn!==g.turn){(g.heartHeals||(g.heartHeals=[])).push({owner:target.owner,target:target.uid,source:artifact.uid});}}
 if(e.targetSnapshot.eq&&hexNum(e.targetSnapshot.eq)===47&&aliveSource)g.tasks.unshift({kind:'abilityDamage',owner:e.targetSnapshot.owner,target:aliveSource.uid,amount:1,source:e.targetSnapshot});
 if(eq===49&&e.targetSnapshot.slot<hexColumns(g)){const behind=g.players[e.targetSnapshot.owner].board[e.targetSnapshot.slot+hexColumns(g)];if(behind&&g.spearUsed?.[source.uid]!==g.turn){(g.spearUsed||(g.spearUsed={}))[source.uid]=g.turn;g.tasks.unshift({kind:'abilityDamage',owner:source.owner,target:behind.uid,amount:1,source});}}
}
function hexArtifactAfter(g,owner,source){hexQueueEvent(g,{kind:'artifactAfter',actor:owner,source:source.uid});}
function hexStartEffect(g,c){hexElderStart(g,c);
 const p=c.owner,pl=g.players[p],n=hexNum(c),mine=pl.board.filter(Boolean),enemies=g.players[1-p].board.slice(0,hexColumns(g)).filter(Boolean),opts=[];
 if(c.burn&&c.burn.due<=pl.turns){c.burn=null;hexDamage(g,[{target:c.uid,amount:2,source:null}]);if(!hexFind(g,c.uid)||g.winner!==null)return;}
 if(n===3){for(const t of enemies)opts.push({label:'Drain '+hexName(t),task:{kind:'eelDrain',owner:p,target:t.uid,source:c}});hexAsk(g,p,'Coiling Current',opts);}
 if(n===4&&pl.deck.length>=2)hexAsk(g,p,'Moonlit Counsel · keep on top',pl.deck.slice(0,2).map(t=>({label:hexName(t),task:{kind:'scryPair',owner:p,keep:t.uid}})));
 if(n===10)for(const t of mine.filter(t=>t.uid!==c.uid&&t.slot%hexColumns(g)===c.slot%hexColumns(g)))hexHeal(g,t,1);
 if(n===36&&c.slot>=hexColumns(g))c.charge=(c.charge||0)+1;
 if(c.eq&&hexNum(c.eq)===50&&pl.deck.length)hexAsk(g,p,'Astral Sight · top card: '+hexName(pl.deck[0]),[{label:'Continue',task:{kind:'noop'}}]);
 if(n===28){c.embers=(c.embers||0)+1;if(c.embers>=3)hexAsk(g,p,'Patient Embers',enemies.map(t=>({label:'Spend 3 embers · '+hexName(t),task:{kind:'emberShot',owner:p,target:t.uid,source:c.uid}})),true);}
 if(n===35&&pl.hand.length){for(const t of mine.filter(t=>t.stunUntil>=g.turn))for(const d of pl.hand)opts.push({label:'Wake '+hexName(t)+' · discard '+hexName(d),task:{kind:'bell',owner:p,target:t.uid,discard:d.uid}});hexAsk(g,p,'Gentle Chime',opts,true);}
 if(n===43&&mine.length===3&&pl.hand.length)hexAsk(g,p,'Constellation',pl.hand.map(d=>({label:'Discard '+hexName(d)+' and draw',task:{kind:'cycle',owner:p,discard:d.uid}})),true);
 if(n===58){for(const t of mine){if(t.burn)opts.push({label:'Remove Burn · '+hexName(t),task:{kind:'garden',owner:p,target:t.uid,mode:'cleanse',source:c.uid}});if(hexDef(t).attack<=1)opts.push({label:'Shield '+hexName(t),task:{kind:'garden',owner:p,target:t.uid,mode:'shield',source:c.uid}});}hexAsk(g,p,'Pocket Constellation',opts,true);}
}
function hexEntry(g,c){if(hexDailyHas(g,'fortified'))hexShield(g,c,2);if(hexKeyword(c,'ward'))c.wardRemaining=hexKeyword(c,'ward');if(hexKeyword(c,'shield'))hexShield(g,c,hexKeyword(c,'shield'));hexArcanaEntry(g,c);hexElderEntry(g,c);if(!hexFind(g,c.uid)||g.winner!==null)return;
 const p=c.owner,pl=g.players[p],n=hexNum(c),mine=pl.board.filter(Boolean),enemy=g.players[1-p],opts=[];
 if(n===5){const top=pl.deck.slice(0,3).filter(t=>hexDef(t).subtype==='Equipment');for(const t of top)opts.push({label:'Take '+hexName(t),task:{kind:'hoardTake',owner:p,target:t.uid}});if(opts.length)hexAsk(g,p,'Treasure Instinct',opts.concat({label:'Take no card',task:{kind:'hoardTake',owner:p,target:null}}));else{const rest=pl.deck.splice(0,3);pl.deck.push(...rest);}}
 if(n===12)hexAsk(g,p,'Northern Lights',enemy.board.filter(Boolean).map(t=>({label:'Weaken '+hexName(t),task:{kind:'debuff',owner:p,target:t.uid,attack:-2}})));
 if(n===17)hexAsk(g,p,'Refreshing Rain',mine.map(t=>({label:'Restore '+hexName(t),task:{kind:'refresh',owner:p,target:t.uid}})));
 if(n===19){for(let i=0;i<hexColumns(g);i++)if(enemy.board[i]&&enemy.board[i+hexColumns(g)])opts.push({label:'Swap enemy column '+(i+1),task:{kind:'swapEnemy',owner:p,column:i}});hexAsk(g,p,'Turnabout Gust',opts,true);}
 if(n===21)hexAsk(g,p,'Unraveling Curse',enemy.board.slice(0,hexColumns(g)).filter(Boolean).map(t=>({label:'Curse '+hexName(t),task:{kind:'shieldCurse',owner:p,target:t.uid}})));
 if(n===27)hexAsk(g,p,'First Light',mine.flatMap(t=>[...(t.burn?[{label:'Remove Burn · '+hexName(t),task:{kind:'dawnCleanse',owner:p,target:t.uid,mode:'burn'}}]:[]),...(t.stunUntil>=g.turn?[{label:'Remove Stun · '+hexName(t),task:{kind:'dawnCleanse',owner:p,target:t.uid,mode:'stun'}}]:[])]));
 if(n===41&&c.slot>=hexColumns(g)){const protector=pl.board[c.slot-hexColumns(g)];if(protector){const add=Math.max(0,2-(protector.winterShield||0));hexShield(g,protector,add);protector.winterShield=2;}}
 // Each reactive artifact may react once to a creature/Equipment play in a turn.
 for(const a of pl.artifacts.filter(Boolean)){if(n&&hexType(c,'Creature')&&hexNum(a)===63&&a.sparkTurn!==g.turn){a.sparkTurn=g.turn;a.sparks=(a.sparks||0)+1;}}
 if(c.slot>=hexColumns(g))for(const a of enemy.artifacts.filter(x=>x&&hexNum(x)===37))if(a.watchTurn!==g.turn){a.watchTurn=g.turn;const front=pl.board[c.slot-hexColumns(g)];if(front)hexAffect(g,1-p,front,()=>hexBuff(g,front,-1));}
}
function hexActiveOptions(g,p){
 if(g.active!==p||!['pre','combat','post'].includes(g.phase)||g.stack.length||g.choice||g.winner!==null)return [];const pl=g.players[p],out=[];
 for(const c of pl.board.filter(Boolean)){
  if(hexNum(c)===9&&c.raiseTurn!==g.turn)for(const discarded of pl.discard.filter(d=>hexType(d,'Creature')&&hexDef(d).attack<=1))for(const cost of pl.hand)out.push({label:'Raise '+hexName(discarded)+' · discard '+hexName(cost),task:{kind:'raise',owner:p,source:c.uid,target:discarded.uid,discard:cost.uid}});
  if(c.eq&&hexNum(c.eq)===54&&c.silkTurn!==g.turn&&pl.board[c.slot<hexColumns(g)?c.slot+hexColumns(g):c.slot-hexColumns(g)])out.push({label:'Silkstep · '+hexName(c),task:{kind:'silkSwap',owner:p,target:c.uid}});
 }
 for(const c of pl.artifacts.filter(Boolean)){
  if(hexNum(c)===42&&c.compassTurn!==g.turn)for(let i=0;i<hexColumns(g);i++)if(pl.board[i]&&pl.board[i+hexColumns(g)])out.push({label:'Course Correction · column '+(i+1),task:{kind:'compassSwap',owner:p,source:c.uid,column:i}});
  if(hexNum(c)===63&&c.sparks>=3&&c.shatterTurn!==g.turn)for(const t of g.players[1-p].board.filter(c=>c?.eq))out.push({label:'Growing Storm · destroy '+hexName(t.eq),task:{kind:'shatter',owner:p,source:c.uid,target:t.uid}});
  if(['pre','post'].includes(g.phase))out.push({label:'Discard '+hexName(c),task:{kind:'discardArtifact',owner:p,source:c.uid}});
 }return out.concat(hexElderActive(g,p));
}
function hexActivate(g,p,index){const option=hexActiveOptions(g,p)[index];if(!option)return false;g.tasks.push(option.task);hexPump(g);return true;}
