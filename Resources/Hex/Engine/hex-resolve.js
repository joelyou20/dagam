"use strict";
function hexExecute(g, j) {
  const previous = g.effectSource;
  g.effectSource =
    j.card ||
    (j.source && (typeof j.source === "object" ? j.source : hexCardUid(g, j.source))) ||
    j.visualSource ||
    (j.uid && hexFind(g, j.uid)) ||
    previous;
  try {
    const result = hexWithVisualBatch(g, () => {
      hexDailyQueueEcho(g, j);
      return hexExecuteTask(g, j);
    });
    hexDailyReactionEcho(g, j);
    return result;
  } finally {
    if (previous) g.effectSource = previous;
    else delete g.effectSource;
  }
}
function hexExecuteTask(g, j) {
  const p = j.owner,
    pl = g.players[p],
    target = j.target ? hexFind(g, j.target) : null;
  switch (j.kind) {
    case "power":
      hexGeneratePower(g, p);
      break;
    case "planeHeal":
      if (target) hexHeal(g, target, 1);
      break;
    case "planeDamage":
      if (target) hexDamage(g, [{ target: target.uid, amount: 1 }]);
      break;
    case "noop":
      break;
    case "dailyEcho":
      if (j.remaining > 1) g.tasks.unshift({ ...j, remaining: j.remaining - 1 });
      if (!hexDailyValidEcho(g, j.original)) break;
      if (j.original.kind === "play")
        hexArcanaExecute(
          g,
          hexArcanaTask(p, "spell", {
            card: j.original.card,
            option: j.original.option,
            copied: true,
          }),
        );
      else hexExecute(g, j.original);
      break;
    case "elderberry":
      hexElderExecute(g, j);
      break;
    case "arcana":
      hexArcanaExecute(g, j);
      break;
    case "prompt":
      hexAsk(g, p, j.label, j.options, j.optional, j.required);
      break;
    case "phase":
      g.phase = j.phase;
      if (j.phase === "pre" || j.phase === "post")
        hexVisualEvent(g, "announcement", {
          text: j.phase === "pre" ? "Pre-Combat Phase" : "Post-Combat Phase",
          tone: "phase",
        });
      if (j.phase === "pre") {
        hexElderPre(g, g.active);
        hexPlanePre(g, g.active);
      }
      if (j.phase === "pre") hexLog(g, "Pre-combat · play cards.");
      if (j.phase === "post") hexLog(g, "Post-combat.");
      break;
    case "draw":
      if (j.skip) hexLog(g, "First player skips the opening draw.");
      else {
        hexDraw(g, p, hexDailyHas(g, "double-draw") ? 2 : 1);
        hexLog(g, hexOwnerLabel(p) + " drew for turn.");
        hexElderAfterDraw(g, p);
      }
      break;
    case "start": {
      const c = hexFind(g, j.uid) || hexArtifact(g, j.uid);
      if (c) hexStartEffect(g, c);
      break;
    }
    case "fieldStart":
      if (g.field && hexNum(g.field) === 52 && pl.deck.length)
        hexAsk(g, p, "Under the Stars · " + hexName(pl.deck[0]), [
          { label: "Keep on top", task: { kind: "noop" } },
          { label: "Put on bottom", task: { kind: "bottomOne", owner: p } },
        ]);
      break;
    case "bottomOne":
      if (pl.deck.length) pl.deck.push(pl.deck.shift());
      break;
    case "scryPair": {
      const pair = pl.deck.splice(0, 2),
        keep = pair.find((c) => c.uid === j.keep);
      if (keep) {
        pl.deck.unshift(keep);
        pl.deck.push(...pair.filter((c) => c !== keep));
      } else pl.deck.unshift(...pair);
      break;
    }
    case "reorderTop": {
      const pair = pl.deck.splice(0, 2);
      pair.sort((a, b) => (a.uid === j.keep ? -1 : b.uid === j.keep ? 1 : 0));
      pl.deck.unshift(...pair);
      break;
    }
    case "hoardTake": {
      const top = pl.deck.splice(0, 3),
        chosen = top.find((c) => c.uid === j.target);
      if (chosen) pl.hand.push(chosen);
      const rest = top.filter((c) => c !== chosen);
      pl.deck.push(...rest);
      if (rest.length === 2)
        hexAsk(
          g,
          p,
          "Treasure Instinct · first on bottom",
          rest.map((c) => ({
            label: hexName(c),
            task: {
              kind: "bottomPair",
              owner: p,
              first: c.uid,
              ids: rest.map((c) => c.uid),
            },
          })),
        );
      break;
    }
    case "bottomPair": {
      const pair = pl.deck.filter((c) => j.ids.includes(c.uid));
      pl.deck = pl.deck.filter((c) => !j.ids.includes(c.uid));
      pair.sort((a, b) => (a.uid === j.first ? -1 : b.uid === j.first ? 1 : 0));
      pl.deck.push(...pair);
      break;
    }
    case "play": {
      const c = j.card,
        n = hexNum(c);
      if (hexType(c, "Spell")) {
        hexArcanaExecute(g, hexArcanaTask(p, "spell", { card: c, option: j.option }));
        break;
      }
      if (hexType(c, "Creature")) {
        if (pl.board[j.option.slot] || !hexCompatible(g, c, p, j.option.slot)) {
          if (hexHasType(c, "Summon")) hexRemoveFromGame(g, c);
          else pl.hand.push(c);
          break;
        }
        const spent = c.spent || {},
          baseHp = c.baseHp;
        hexResetInstance(c);
        Object.assign(c, {
          owner: p,
          slot: j.option.slot,
          spent,
          baseHp,
          playedTurn: g.turn,
          playedOwnerTurn: pl.turns,
          hp: hexDailyBase(g, c).hp,
          maxHp: hexDailyBase(g, c).hp,
          shield: 0,
          mods: [],
          attackBonus: 0,
        });
        pl.board[c.slot] = c;
        hexLog(g, hexOwnerLabel(p) + " played " + hexName(c) + ".");
        hexRefresh(g);
        hexEntry(g, c);
        if (hexFind(g, c.uid))
          hexQueueEvent(g, {
            kind: "creatureEntered",
            actor: p,
            target: c.uid,
          });
      } else if (hexType(c, "Battlefield")) {
        if (g.field) g.players[g.field.owner].discard.push(g.field);
        g.field = c;
        hexLog(g, hexName(c) + " is the shared Battlefield.");
      } else if (hexDef(c).subtype === "Artifact") {
        const old = pl.artifacts[j.option.slot];
        if (old) pl.discard.push(old);
        c.owner = p;
        pl.artifacts[j.option.slot] = c;
        hexLog(g, hexOwnerLabel(p) + " played " + hexName(c) + ".");
      } else if (hexDef(c).subtype === "Equipment") {
        const bearer = hexFind(g, j.option.target);
        if (!bearer || bearer.owner !== p) {
          pl.discard.push(c);
          break;
        }
        if (bearer.eq) pl.discard.push(bearer.eq);
        bearer.eq = c;
        hexLog(g, hexName(c) + " equipped to " + hexName(bearer) + ".");
        hexRefresh(g);
        if (n === 55 && pl.deck.length >= 2)
          hexAsk(
            g,
            p,
            "Pack Light · first on top",
            pl.deck.slice(0, 2).map((d) => ({
              label: hexName(d),
              task: { kind: "reorderTop", owner: p, keep: d.uid },
            })),
          );
        for (const artifact of pl.artifacts.filter((a) => a && hexNum(a) === 25))
          if (artifact.coinTurn !== g.turn && pl.deck.length) {
            artifact.coinTurn = g.turn;
            hexAsk(
              g,
              p,
              "Measured Fortune · " + hexName(pl.deck[0]),
              [
                { label: "Keep on top", task: { kind: "noop" } },
                {
                  label: "Put on bottom",
                  task: { kind: "bottomOne", owner: p },
                },
              ],
              false,
            );
          }
      }
      break;
    }
    case "special": {
      const n = j.num,
        f = g.stack.find((f) => f.id === j.parent),
        o = j.option;
      if (hexElderNum(j.card) === 41) {
        const t = hexFind(g, o.target);
        if (t?.summoned) hexAffect(g, p, t, () => hexArcanaKill(g, t), true, j.card, true);
      }
      if (hexElderNum(j.card) === 49) {
        const t = hexFind(g, o.target);
        if (t && !pl.board[o.slot])
          hexAffect(g, p, t, () => {
            t.originalOwner = hexOriginalOwner(t);
            const ctrl = { owner: t.owner, slot: t.slot, until: g.turn + 1 };
            g.players[t.owner].board[t.slot] = null;
            t.owner = p;
            t.slot = o.slot;
            t.control = ctrl;
            pl.board[o.slot] = t;
            hexElderGrant(g, t, "sprint", 1, g.turn + 1);
          });
      }
      if (n === 33) {
        const t = hexFind(g, o.target);
        if (t) {
          if (o.mode === "heal") {
            hexHeal(g, t, 2);
          } else hexAbilityDamage(g, p, t.uid, 1, j.card, { special: true });
        }
      }
      if (n === 39) {
        const i = pl.discard.findIndex((c) => c.uid === o.target && hexType(c, "Creature"));
        if (i >= 0) {
          const c = pl.discard.splice(i, 1)[0];
          hexResetInstance(c);
          c.blockedUntil = g.turn;
          pl.hand.push(c);
        }
      }
      if (n === 46 && f) {
        const opts = hexSpecialOptions(g, p, j.card, f);
        if (opts.some((opt) => opt.target === o.target)) {
          f.job.option.target = o.target;
          f.event.target = o.target;
        }
      }
      if (n === 62) {
        const a = g.attacks.find((a) => a.id === o.target);
        if (a) {
          a.canceled = true;
          hexVisualEvent(g, "counter", {
            source: hexVisualCard(j.card),
            target: hexVisualCard(hexFind(g, a.attacker)),
          });
        }
      }
      if ((n === 64 || hexArcanaNum(j.card) === 35) && f) {
        f.canceled = true;
        hexVisualEvent(g, "counter", {
          source: hexVisualCard(j.card),
          target: hexVisualCard(f.job.card),
        });
      }
      if (!j.dailyEcho) pl.discard.push(j.card);
      hexLog(g, hexName(j.card) + " resolved.");
      break;
    }
    case "attackTrigger": {
      const a = hexFind(g, j.attacker),
        t = hexFind(g, j.target);
      if (!a || !t || g.attacks.find((a) => a.id === j.attack)?.canceled) break;
      hexArcanaAttack(g, a);
      hexElderAttack(g, a);
      if (hexNum(a) === 36 && a.charge > 0)
        hexAsk(g, a.owner, "Gathering Thunder", [
          {
            label: "Spend a charge · +2 Attack",
            task: {
              kind: "chargeAttack",
              owner: a.owner,
              attack: j.attack,
              source: a.uid,
            },
          },
          { label: "Save the charge", task: { kind: "noop" } },
        ]);
      if (hexNum(a) === 16 && t.slot < hexColumns(g)) {
        const rear = g.players[t.owner].board[t.slot + hexColumns(g)];
        if (rear) hexAbilityDamage(g, a.owner, rear.uid, 1, a);
      }
      break;
    }
    case "chargeAttack": {
      const a = hexFind(g, j.source),
        attack = g.attacks.find((v) => v.id === j.attack);
      if (a?.charge > 0 && attack && !attack.canceled) {
        a.charge--;
        attack.chargeBonus = 2;
      }
      break;
    }
    case "combat":
      hexCombat(g);
      break;
    case "strike":
      hexCombat(g, j.attack);
      break;
    case "afterStrike":
      break;
    case "combatHit":
      hexCombatHit(g, j);
      break;
    case "abilityDamage":
      hexAbilityDamage(g, p, j.target, j.amount, j.source);
      break;
    case "blast":
      hexDamage(
        g,
        j.targets.map((target) => ({
          target,
          amount: j.amount,
          source: j.source,
          untargeted: true,
        })),
      );
      break;
    case "eelDrain": {
      const t = hexFind(g, j.target);
      if (t) {
        const wounded = t.hp < t.maxHp;
        hexAffect(g, p, t, () => {
          hexDamage(g, [{ source: j.source, target: t.uid, amount: 1, wardChecked: true }]);
          const live = hexFind(g, t.uid);
          if (wounded && live) hexStun(g, live);
        });
      }
      break;
    }
    case "debuff":
      if (target)
        hexAffect(g, p, target, () =>
          hexBuff(g, target, j.attack, hexNextOwnerEnd(g, target.owner)),
        );
      break;
    case "refresh":
      if (target) {
        target.burn = null;
        hexHeal(g, target, 2);
      }
      break;
    case "dawnCleanse":
      if (target) {
        if (j.mode === "burn") target.burn = null;
        else target.stunUntil = 0;
        hexHeal(g, target, 1);
      }
      break;
    case "shieldCurse":
      if (target)
        hexAffect(g, p, target, () => {
          target.shield = 0;
          target.noShieldUntil = g.turn + 2;
        });
      break;
    case "swapEnemy": {
      const ep = g.players[1 - p],
        a = ep.board[j.column],
        b = ep.board[j.column + hexColumns(g)];
      if (a && b && !(a.eq && hexNum(a.eq) === 38) && !(b.eq && hexNum(b.eq) === 38))
        hexAffect(g, p, a, () =>
          hexAffect(g, p, b, () => hexSwap(g, 1 - p, j.column, j.column + hexColumns(g))),
        );
      break;
    }
    case "returnEnemy":
      if (target) hexAffect(g, p, target, () => hexReturn(g, target));
      break;
    case "emberShot": {
      const source = hexArtifact(g, j.source);
      if (source?.embers >= 3 && target) {
        source.embers -= 3;
        const before = target.hp;
        hexAbilityDamage(g, p, target.uid, 2, source, { artifact: true });
        if (target.hp < before) hexArtifactAfter(g, p, source);
      }
      break;
    }
    case "bell":
      if (target && target.stunUntil >= g.turn) {
        const cost = hexDiscardFromHand(g, p, j.discard);
        if (cost) {
          pl.discard.push(cost);
          target.stunUntil = 0;
        }
      }
      break;
    case "cycle": {
      const cost = hexDiscardFromHand(g, p, j.discard);
      if (cost) {
        pl.discard.push(cost);
        hexDraw(g, p);
      }
      break;
    }
    case "garden": {
      const source = hexArtifact(g, j.source);
      if (source && target) {
        if (j.mode === "cleanse") target.burn = null;
        else hexShield(g, target, 1);
      }
      break;
    }
    case "raise": {
      const source = hexFind(g, j.source),
        i = pl.discard.findIndex((c) => c.uid === j.target);
      if (source && source.raiseTurn !== g.turn && i >= 0) {
        const cost = hexDiscardFromHand(g, p, j.discard);
        if (cost) {
          const c = pl.discard.splice(i, 1)[0];
          pl.discard.push(cost);
          source.raiseTurn = g.turn;
          hexResetInstance(c);
          pl.hand.push(c);
        }
      }
      break;
    }
    case "silkSwap":
      if (target && target.silkTurn !== g.turn) {
        const other =
          target.slot < hexColumns(g) ? target.slot + hexColumns(g) : target.slot - hexColumns(g);
        if (hexSwap(g, p, target.slot, other)) {
          target.silkTurn = g.turn;
          hexBuff(g, target, 1);
        }
      }
      break;
    case "compassSwap": {
      const a = hexArtifact(g, j.source);
      if (a && a.compassTurn !== g.turn && hexSwap(g, p, j.column, j.column + hexColumns(g)))
        a.compassTurn = g.turn;
      break;
    }
    case "shatter": {
      const a = hexArtifact(g, j.source);
      if (a?.sparks >= 3 && target?.eq) {
        a.sparks -= 3;
        a.shatterTurn = g.turn;
        hexAffect(g, p, target, () => {
          hexVisualEvent(g, "destroy", hexVisualCard(target.eq));
          g.players[target.owner].discard.push(target.eq);
          target.eq = null;
        });
      }
      break;
    }
    case "discardArtifact": {
      const i = pl.artifacts.findIndex((a) => a?.uid === j.source);
      if (i >= 0) {
        pl.discard.push(pl.artifacts[i]);
        pl.artifacts[i] = null;
      }
      break;
    }
    case "postEffects": {
      hexElderPost(g, p);
      for (const c of pl.board.filter(Boolean)) {
        const attacked = (g.combatParticipants || []).includes(c.uid),
          e = c.eq ? hexNum(c.eq) : 0;
        if (attacked && e === 45)
          g.tasks.push({
            kind: "abilityDamage",
            owner: p,
            target: c.uid,
            amount: 1,
            source: c,
          });
        if (!attacked && e === 57) hexHeal(g, c, 1);
      }
      const heals = g.heartHeals || [];
      g.heartHeals = [];
      for (const source of [...new Set(heals.map((h) => h.source))]) {
        const a = hexArtifact(g, source);
        if (!a || a.rootTurn === g.turn) continue;
        const targets = [...new Set(heals.filter((h) => h.source === source).map((h) => h.target))]
          .map((uid) => hexFind(g, uid))
          .filter((c) => c && c.hp < c.maxHp);
        hexAsk(
          g,
          a.owner,
          "Roots Remember",
          targets.map((c) => ({
            label: "Heal " + hexName(c),
            task: { kind: "heartHeal", owner: a.owner, source, target: c.uid },
          })),
          true,
        );
      }
      const returns = g.ashReturns || [];
      g.ashReturns = [];
      for (const r of returns) {
        const d = g.players[r.owner],
          i = d.discard.findIndex((c) => c.uid === r.uid);
        if (i >= 0) {
          const c = d.discard.splice(i, 1)[0];
          hexResetInstance(c);
          c.baseHp = 3;
          d.hand.push(c);
        }
      }
      if (g.field && hexNum(g.field) === 44)
        hexAsk(
          g,
          p,
          "After the Rain",
          pl.board
            .filter((c) => c && c.hp < c.maxHp && !(g.combatParticipants || []).includes(c.uid))
            .map((c) => ({
              label: "Heal " + hexName(c),
              task: { kind: "fieldHeal", owner: p, target: c.uid },
            })),
          true,
        );
      break;
    }
    case "heartHeal": {
      const a = hexArtifact(g, j.source);
      if (a && a.rootTurn !== g.turn && target) {
        a.rootTurn = g.turn;
        if (hexHeal(g, target, 1)) hexArtifactAfter(g, p, a);
      }
      break;
    }
    case "fieldHeal":
      if (target && hexElderNum(target.eq) !== 33) hexHeal(g, target, 1);
      break;
    case "endTurn":
      hexLog(g, "End of turn.");
      hexElderEnd(g);
      hexArcanaEnd(g);
      if (g.winner !== null) break;
      for (const c of g.players[g.active].board.filter(Boolean))
        if (hexKeyword(c, "regeneration") || hexDailyHas(g, "renewal"))
          hexHeal(g, c, hexKeyword(c, "regeneration") + (hexDailyHas(g, "renewal") ? 1 : 0));
      if (!g.players[g.active].board.some(Boolean) && g.players[1 - g.active].board.some(Boolean)) {
        g.winner = 1 - g.active;
        g.lossReason = "emptyField";
        g.phase = "over";
        g.tasks = [];
        g.stack = [];
        g.choice = null;
        hexLog(g, hexOwnerLabel(g.active) + " ended the turn with no active creatures.");
        break;
      }
      g.active = 1 - g.active;
      hexBeginTurn(g);
      break;
    default:
      throw Error("Unknown Hex task: " + j.kind);
  }
}
