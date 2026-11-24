'use strict';
const HEX_MATCH_ROUND_LIMIT=60;
/* Serializable, seeded turn engine. It never reads lifestyle stats or mutates the collection. */
const hexDef=c=>HEX_CARD[typeof c==='string'?c:c.id];
const hexNum=c=>hexDef(c).number+(hexDef(c).set==='shattered-arcana'?100:hexDef(c).set==='war-on-elderberry'?200:0);
const hexType=(c,t)=>hexDef(c).card_type===t;
const hexRand=g=>((g.seed=(Math.imul(g.seed,1664525)+1013904223)>>>0)/4294967296);
function hexShuffle(g,items){const a=items.slice();for(let i=a.length-1;i>0;i--){const j=Math.floor(hexRand(g)*(i+1));[a[i],a[j]]=[a[j],a[i]];}return a;}
function hexLog(g,message){g.log.push(message);g.log=g.log.slice(-80);}
const hexAll=g=>g.players.flatMap(p=>p.board.filter(Boolean));
const hexFind=(g,uid)=>hexAll(g).find(c=>c.uid===uid);
const hexArtifact=(g,uid)=>g.players.flatMap(p=>p.artifacts.filter(Boolean)).find(c=>c.uid===uid);
const hexFront=g=>g.players.map(p=>p.board.slice(0,hexColumns(g)).filter(Boolean));
const hexCardUid=(g,uid)=>hexFind(g,uid)||hexArtifact(g,uid)||g.players.flatMap(p=>[...p.hand,...p.discard,...p.deck,...(p.exile||[])]).find(c=>c.uid===uid);
const hexName=c=>c?hexDef(c).name:'Creature';
const hexOriginalOwner=(c,fallback=c.owner)=>[0,1].includes(c.originalOwner)?c.originalOwner:[0,1].includes(c.control?.owner)?c.control.owner:fallback;
const hexOwnerLabel=p=>p===0?'You':'The bot';
function hexNewGame(playerDeck,botDeck,seed=Date.now(),options={}){
 const g={v:1,rules:{...hexFormat(options.format)},context:options.context||null,challengeStats:{plays:0,nonCreature:0,spellsByDay:{}},seed:seed>>>0,serial:0,turn:0,active:0,phase:'opening',winner:null,players:[],field:null,tasks:[],stack:[],choice:null,attacks:[],log:[],recorded:false,fx:[],fxSerial:0,fxAck:0};
 for(const ids of [playerDeck,botDeck]){const player=g.players.length,deck=ids.map(id=>({uid:'hc-'+(++g.serial),id,owner:player,originalOwner:player,spent:{}}));g.players.push({deck:hexShuffle(g,deck),hand:[],board:Array(hexRules(g).slots).fill(null),artifacts:Array(hexRules(g).artifactSlots).fill(null),discard:[],losses:0,mulligan:false,turns:0});if(!options.interactiveCoin)hexDraw(g,player,hexRules(g).opening);}
 if(options.interactiveCoin){g.phase='coin';g.coin={call:null,face:null,winner:null};return g;}
 g.first=g.active=hexRand(g)<.5?0:1;hexLog(g,(g.first===0?'You won':'The bot won')+' the coin flip and will go first.');
 const bot=g.players[1],creatures=bot.hand.filter(c=>hexType(c,'Creature')).length;if(creatures<2||creatures>4){bot.deck=hexShuffle(g,bot.deck.concat(bot.hand));bot.hand=[];hexDraw(g,1,hexRules(g).opening);bot.mulligan=true;}
 return g;
}
function hexDraw(g,p,n=1){const pl=g.players[p];for(let i=0;i<n&&pl.deck.length;i++){const c=pl.deck.shift();pl.hand.push(c);hexVisualEvent(g,'draw',{player:p,uid:c.uid,id:c.id});hexArcanaDraw(g,p,c);hexElderDraw(g,p);}}
function hexMulligan(g,p){if(g.phase!=='opening'||g.players[p].mulligan)return false;const pl=g.players[p];pl.deck=hexShuffle(g,pl.deck.concat(pl.hand));pl.hand=[];hexDraw(g,p,hexRules(g).opening);pl.mulligan=true;return true;}
function hexKeep(g){if(g.phase!=='opening')return false;hexBeginTurn(g);return true;}
function hexBeginTurn(g){
 if(g.winner!==null)return;if(!g.context?.dailyDay&&g.turn>=HEX_MATCH_ROUND_LIMIT*2){g.winner=-1;g.phase='over';g.drawReason='roundLimit';g.tasks=[];g.stack=[];g.choice=null;hexLog(g,'Draw · Match reached '+HEX_MATCH_ROUND_LIMIT+' full rounds.');return;}if(g.context?.dailyDay&&g.turn>=HEX_DAILY_ROUND_LIMIT*2){g.winner=-1;g.phase='over';g.drawReason='dailyRoundLimit';g.tasks=[];g.stack=[];g.choice=null;hexLog(g,'Draw · Daily Challenge reached '+HEX_DAILY_ROUND_LIMIT+' full rounds.');return;}g.turn++;const p=g.players[g.active];p.turns++;g.phase='start';g.attacks=[];hexVisualEvent(g,'announcement',{text:g.active===0?'Your Turn':"Enemy’s Turn",tone:g.active===0?'player':'enemy'});hexLog(g,'Turn '+hexTurnNumber(g)+' · '+hexOwnerLabel(g.active)+'.');
 for(const c of [...p.board,...p.artifacts].filter(Boolean))g.tasks.push({kind:'start',uid:c.uid,owner:g.active});if(g.field)g.tasks.push({kind:'fieldStart',owner:g.active});
 g.tasks.push({kind:'draw',owner:g.active,skip:g.turn===1},{kind:'phase',phase:'pre'});hexPump(g);
}
function hexStats(g,c,skipBrooch=false){
 const def=hexDef(c),n=hexNum(c),e=c.eq?hexNum(c.eq):0;let attack=hexDailyBase(g,c).attack+(c.attackBonus||0),maxHp=hexDailyBase(g,c).hp;
 attack+=({34:1,45:2,49:1,53:1,56:1})[e]||0;maxHp+=({23:1,38:1,47:2,53:1,55:1,57:1,59:1,61:1})[e]||0;
 if(e===50&&c.slot>=hexColumns(g))attack++;
 if(n===18)attack+=c.slot>=hexColumns(g)&&g.players[c.owner].board[c.slot-hexColumns(g)]?2:-1;
 for(const m of c.mods||[])if(m.until>=g.turn){attack+=m.attack||0;maxHp+=m.maxHp||0;}
 if(hexHasType(c,'Mage'))attack+=g.players[c.owner].board.filter(a=>a&&a.uid!==c.uid&&hexArcanaNum(a)===44).length;
 attack-=g.players[1-c.owner].board.filter(a=>a&&hexArcanaNum(a)===46&&a.slot%hexColumns(g)===c.slot%hexColumns(g)).length;
 if(c.slot<hexColumns(g)&&g.players[c.owner].board[c.slot+hexColumns(g)]&&hexNum(g.players[c.owner].board[c.slot+hexColumns(g)])===15)maxHp+=2;
 if(g.field&&hexElderNum(c.eq)!==33&&hexNum(g.field)===48&&hexHasType(def,'Dragon'))maxHp++;
 maxHp=Math.max((c.mods||[]).some(m=>m.maxHp<0&&m.until>=g.turn)?0:1,maxHp-(c.scars||0));return hexElderStats(g,c,attack,maxHp,skipBrooch);
}
function hexRefresh(g){hexElderExile(g);for(const c of hexAll(g)){const max=hexStats(g,c).maxHp,old=c.maxHp||max;c.hp=Math.min(max,c.hp+Math.max(0,max-old));c.maxHp=max;}}
function hexBuff(g,c,attack,until=g.turn){if(c){c.mods.push({attack,until});if(attack)hexVisualEvent(g,'status',{...hexVisualCard(c),text:(attack>0?'+':'')+attack+' ATK',positive:attack>0});}}
const hexNextOwnerEnd=(g,owner)=>g.turn+(g.active===owner?2:1);
function hexStun(g,c){if(!c)return;const before=g.active===c.owner&&['start','pre'].includes(g.phase)&&(hexRuntimeKeyword(g,c,'sprint')||c.playedTurn<g.turn)&&(hexNum(c)!==16||g.players[c.owner].turns>=c.playedOwnerTurn+2);c.stunUntil=Math.max(c.stunUntil||0,before?g.turn:hexNextOwnerEnd(g,c.owner));}
function hexShield(g,c,n){if(!c||c.noShieldUntil>=g.turn||g.field&&hexElderNum(c.eq)!==33&&hexNum(g.field)===60&&c.slot<hexColumns(g))return;c.shield=(c.shield||0)+n;if(n>0)hexVisualEvent(g,'status',{...hexVisualCard(c),text:'+'+n+' Shield',positive:true});}
function hexHeal(g,c,n){if(!c)return 0;const before=c.hp;c.hp=Math.min(hexStats(g,c).maxHp,c.hp+n);const actual=c.hp-before;if(actual>0)hexVisualEvent(g,'heal',{uid:c.uid,id:c.id,owner:c.owner,slot:c.slot,amount:actual});if(actual&&c.eq&&hexNum(c.eq)===59&&c.crownTurn!==g.turn){c.crownTurn=g.turn;hexBuff(g,c,1);}return actual;}
function hexLegalTargets(g,attacker){const p=g.players[1-attacker.owner],bypass=hexRuntimeKeyword(g,attacker,'ranged')||attacker.eq&&hexNum(attacker.eq)===40;const forced=p.board.filter(c=>c&&c.tauntUntil>=g.turn);return p.board.filter(c=>c&&c.invisibleUntil==null&&(!forced.length||forced.includes(c))&&(forced.includes(c)||c.slot<hexColumns(g)||!p.board[c.slot-hexColumns(g)]||bypass)&&(hexNum(attacker)!==8||c.slot<hexColumns(g)));}
function hexReady(g,c){return c.owner===g.active&&c.hp>0&&!(c.stunUntil>=g.turn)&&!g.attacks.some(a=>a.attacker===c.uid)&&(hexRuntimeKeyword(g,c,'sprint')||c.playedTurn<g.turn)&&(hexNum(c)!==16||g.players[c.owner].turns>=c.playedOwnerTurn+2)&&hexNum(c)!==3;}
function hexQueueEvent(g,event,job={kind:'noop'}){g.stack.push({id:'hf-'+(++g.serial),event,job,priority:1-event.actor,passes:0});}
function hexReactionCards(g,p){const top=g.stack.at(-1);if(!top)return [];return g.players[p].hand.filter(c=>(hexIsReaction(c)||hexKeyword(c,'ambush'))&&hexSpecialOptions(g,p,c,top).length);}
function hexPump(g){
 let steps=0;hexRefresh(g);
 while(g.winner===null&&!g.choice&&steps++<1000){
  const f=g.stack.at(-1);if(f){if(f.passes<2){if(hexReactionCards(g,f.priority).length)return;f.passes++;f.priority=1-f.priority;continue;}g.stack.pop();if(f.canceled){if(f.job.card)g.players[f.job.card.owner].discard.push(f.job.card);hexLog(g,'Canceled · '+(f.job.card?hexName(f.job.card):'attack'));}else hexExecute(g,f.job);hexRefresh(g);continue;}
  const task=g.tasks.shift();if(!task)break;hexExecute(g,task);hexRefresh(g);
 }
 if(steps>=1000){g.winner=-1;g.phase='over';hexLog(g,'Draw: repeated effect safety limit.');}
}
function hexPass(g,p){const f=g.stack.at(-1);if(!f||f.priority!==p)return false;f.passes++;f.priority=1-p;hexPump(g);return true;}
function hexAsk(g,p,label,options,optional=false,required=false){options=options.filter(o=>!o.task?.target||hexFind(g,o.task.target)?.invisibleUntil==null||o.task.kind==='elderberry'&&['sacrifice'].includes(o.task.op));if(!options.length)return;if(g.effectSource)options=options.map(o=>({...o,task:{...o.task,visualSource:o.task.visualSource||hexVisualCard(g.effectSource)}}));if(g.choice){g.tasks.unshift({kind:'prompt',owner:p,label,options,optional,required});return;}if(optional)options.push({label:'Skip',task:{kind:'noop'}});g.choice={player:p,label,options,required};}
function hexChoose(g,p,index){if(g.choice?.player!==p||!Number.isInteger(index)||!g.choice.options[index])return false;const task=g.choice.options[index].task;g.choice=null;g.tasks.unshift(task);hexPump(g);return true;}
function hexDiscardFromHand(g,p,uid){const pl=g.players[p],i=pl.hand.findIndex(c=>c.uid===uid);if(i<0)return null;return pl.hand.splice(i,1)[0];}
function hexSpecialOptions(g,p,c,f=g.stack.at(-1)){
 if(!f||g.winner!==null)return [];const e=f.event,n=hexNum(c),mine=g.players[p],enemy=g.players[1-p],option=(label,extra={})=>({label,...extra});
 if(hexKeyword(c,'ambush')&&e.kind==='combatStart'&&e.actor!==p)return mine.board.flatMap((t,slot)=>!t?[option('Ambush · slot '+(slot+1),{slot})]:[]);
 if([41,49].includes(hexElderNum(c))&&e.kind==='creatureEntered'&&e.actor!==p){const t=hexFind(g,e.target);if(t&&(hexElderNum(c)===49||t.summoned))return hexElderNum(c)===41?[option('Unsummon '+hexName(t),{target:t.uid})]:mine.board.flatMap((a,slot)=>!a?[option('Control '+hexName(t)+' · slot '+(slot+1),{target:t.uid,slot})]:[]);}
 if(hexArcanaNum(c)===35&&e.actor!==p&&f.job.card&&hexType(f.job.card,'Spell'))return [option('Counter '+hexName(f.job.card),{target:f.id})];
 if(n===33&&e.kind==='artifactAfter'&&e.actor!==p)return [...mine.board.filter(c=>c&&c.hp<c.maxHp&&hexSpellTargetable(c)).map(t=>option('Heal '+hexName(t),{mode:'heal',target:t.uid})),...enemy.board.slice(0,hexColumns(g)).filter(t=>t&&hexSpellTargetable(t)&&!hexProtectedFromSpecial(g,t)).map(t=>option('Deal 1 to '+hexName(t),{mode:'damage',target:t.uid}))];
 if(n===39&&e.kind==='death'&&e.owner===p&&mine.discard.some(d=>d.uid===e.dead))return [option('Return '+hexName(hexCardUid(g,e.dead)),{target:e.dead})];
 if(n===46&&e.actor!==p&&f.job.card&&hexType(f.job.card,'Spell')&&e.target&&hexFind(g,e.target)?.owner===p&&!f.job.option?.other){const opts=hexArcanaNum(f.job.card)?hexArcanaOptions(g,f.job.owner,f.job.card):f.job.num===33&&f.job.option.mode==='damage'?mine.board.slice(0,hexColumns(g)).filter(t=>t&&hexSpellTargetable(t)&&!hexProtectedFromSpecial(g,t)).map(t=>({target:t.uid})):[];return opts.filter(o=>o.target&&o.target!==e.target&&!o.other&&hexFind(g,o.target)).map(o=>option('Redirect to '+hexName(hexFind(g,o.target)),{target:o.target}));}
 if(n===62&&e.kind==='attack'&&e.actor!==p&&g.attacks.some(a=>a.id===e.attack&&!a.canceled))return [option('Cancel '+hexName(hexFind(g,e.attacker))+'’s attack',{target:e.attack})];
 if(n===64&&e.kind==='play'&&e.actor!==p&&['Artifact','Battlefield'].includes(e.type))return [option('Cancel '+hexName(f.job.card),{target:f.id})];return [];
}
function hexPlayOptions(g,p,card){if(card.blockedUntil>=g.turn)return [];
 if(hexKeyword(card,'ambush')&&g.stack.at(-1)?.priority===p&&g.stack.at(-1).event.kind==='combatStart')return hexSpecialOptions(g,p,card);
 if(hexIsReaction(card))return g.stack.at(-1)?.priority===p?hexSpecialOptions(g,p,card):[];
 if(p!==g.active||!['pre','post'].includes(g.phase)||g.stack.length||g.choice)return [];const pl=g.players[p],n=hexNum(card);if(card.blockedUntil>=g.turn)return [];
 if(hexType(card,'Spell'))return hexArcanaOptions(g,p,card);
 if(hexType(card,'Creature'))return pl.board.flatMap((c,slot)=>!c&&(n!==8||slot<hexColumns(g))&&(n!==227||slot>=hexColumns(g))?[{label:(slot<hexColumns(g)?'Front':'Back')+' · column '+(slot%hexColumns(g)+1),slot}]:[]);
 if(hexType(card,'Battlefield'))return [{label:'Replace the shared Battlefield'}];
 if(hexDef(card).subtype==='Artifact')return pl.artifacts.map((_,slot)=>({label:(pl.artifacts[slot]?'Replace '+hexName(pl.artifacts[slot]):'Empty artifact slot')+' · '+(slot+1),slot}));
 if(hexDef(card).subtype==='Equipment')return pl.board.filter(Boolean).map(t=>({label:'Equip '+hexName(t)+(t.eq?' (replace '+hexName(t.eq)+')':''),target:t.uid}));return [];
}
function hexPlay(g,p,uid,index=0){
 if(g.winner!==null)return false;const c=g.players[p].hand.find(c=>c.uid===uid);if(!c)return false;const options=hexPlayOptions(g,p,c),option=options[index];if(!option)return false;
 const ambush=hexKeyword(c,'ambush')&&g.stack.at(-1)?.event.kind==='combatStart';if(ambush){g.stack.at(-1).passes=0;g.stack.at(-1).priority=1-p;}const special=hexIsReaction(c),parent=g.stack.at(-1);hexDiscardFromHand(g,p,uid);
 if(hexType(c,'Spell'))hexArcanaCast(g,p,c,option);
 if(special){parent.passes=0;parent.priority=1-p;hexQueueEvent(g,{kind:'special',actor:p,target:option.target},{kind:'special',card:c,num:hexNum(c),owner:p,option,parent:parent.id,event:parent.event});}
 else hexQueueEvent(g,{kind:'play',actor:p,target:option.target,type:hexType(c,'Spell')?'Spell':hexType(c,'Battlefield')?'Battlefield':hexDef(c).subtype},{kind:'play',card:c,owner:p,option});
 hexPump(g);return true;
}
function hexDeclare(g,p,attacker,target){
 if(g.winner!==null||g.phase!=='combat'||p!==g.active||g.stack.length||g.choice)return false;const a=hexFind(g,attacker),t=hexFind(g,target);if(!a||!t||!hexReady(g,a)||!hexLegalTargets(g,a).some(c=>c.uid===target))return false;
 const attack={id:'ha-'+(++g.serial),attacker,target,canceled:false};g.attacks.push(attack);hexQueueEvent(g,{kind:'attack',actor:p,attack:attack.id,attacker,target},{kind:'attackTrigger',attacker,target,attack:attack.id});g.tasks.push({kind:'strike',attack:attack.id},{kind:'afterStrike'});hexPump(g);return true;
}
function hexNext(g,p){
 if(p!==g.active||g.winner!==null||g.stack.length||g.choice)return false;
 if(g.phase==='pre'){g.phase='combat';g.combatParticipants=[];hexVisualEvent(g,'announcement',{text:'Combat Phase',tone:'phase'});hexLog(g,'Choose attacks.');hexQueueEvent(g,{kind:'combatStart',actor:p});hexPump(g);}
 else if(g.phase==='combat'){if(g.players[p].board.some(c=>c&&hexElderNum(c)===13&&hexReady(g,c)&&hexLegalTargets(g,c).length))return false;g.phase='resolve';g.tasks.push({kind:'combat'},{kind:'postEffects',owner:g.active},{kind:'phase',phase:'post'});hexPump(g);}
 else if(g.phase==='post'){g.phase='end';g.tasks.push({kind:'endTurn'});hexPump(g);}else return false;return true;
}
function hexConcede(g,p=0){if(g.winner!==null)return false;g.winner=1-p;g.phase='over';g.choice=null;g.tasks=[];g.stack=[];hexLog(g,hexOwnerLabel(p)+' conceded.');return true;}

function hexVisualEvent(g,kind,data){g.fxSerial=(g.fxSerial||0)+1;const event={serial:g.fxSerial,kind,...(g.fxBatch?{batch:g.fxBatch}:{}),...data};(g.fx||(g.fx=[])).push(event);g.fx=g.fx.slice(-100);return event;}
function hexCallCoin(g,call){if(g.phase!=='coin'||!['heads','tails'].includes(call))return false;const face=hexRand(g)<.5?'heads':'tails';g.coin={call,face,winner:call===face?0:1};g.phase='coinResult';hexLog(g,'Coin: '+face+' · '+(g.coin.winner===0?'You':'The bot')+' won.');return true;}
function hexChooseFirst(g,first){if(g.phase!=='coinResult'||![0,1].includes(first)||g.coin.winner===1&&first!==1)return false;g.first=g.active=first;g.phase='opening';hexDraw(g,0,hexRules(g).opening);hexDraw(g,1,hexRules(g).opening);const bot=g.players[1],n=bot.hand.filter(c=>hexType(c,'Creature')).length;if(n<2||n>4){bot.deck=hexShuffle(g,bot.deck.concat(bot.hand));bot.hand=[];hexDraw(g,1,hexRules(g).opening);bot.mulligan=true;}hexLog(g,(first===0?'You go':'The bot goes')+' first.');return true;}

function hexSkipChoice(g,p){if(!hexCanSkipChoice(g,p))return false;const index=g.choice.options.findIndex(o=>['Skip','Take no card','Save the charge','Continue','Keep on top'].includes(o.label));if(index>=0)return hexChoose(g,p,index);hexLog(g,'Skipped · '+g.choice.label);g.choice=null;hexPump(g);return true;}

function hexWithVisualBatch(g,fn){if(g.fxBatch)return fn();g.fxBatch=(g.fxBatchSerial||0)+1;g.fxBatchSerial=g.fxBatch;try{return fn();}finally{delete g.fxBatch;}}

// g.turn remains the saved per-player phase clock for effect expiry; card turn numbers count full table rounds.
const hexTurnNumber=g=>Math.ceil((g.turn||0)/2);

function hexCanSkipChoice(g,p){return !!g.choice&&g.choice.player===p&&g.winner===null&&!g.choice.required&&!g.choice.options.every(o=>o.task?.kind==='arcana'&&o.task.op==='discard');}
