"use strict";
/* Shattered Arcana: all choices and delayed effects remain serializable in the match. */
const hexArcanaNum = (c) => (c && hexDef(c)?.set === "shattered-arcana" ? hexDef(c).number : 0);
const hexRuntimeKeyword = (g, c, id) =>
  hexElderKeyword(g, c, id) ||
  (["sprint", "ranged"].includes(id) && hexDailyHas(g, id) ? 1 : 0) ||
  hexKeyword(c, id) ||
  ((c.grants || []).some((k) => k.id === id && k.until >= g.turn) ? 1 : 0);
const hexSpellTargetable = (c) => c.invisibleUntil == null && !(c.eq && hexArcanaNum(c.eq) === 30);
const hexArcanaTask = (owner, op, extra = {}) => ({
  kind: "arcana",
  owner,
  op,
  ...extra,
});
function hexArcanaOptions(g, p, card) {
  if (hexElderNum(card)) return hexElderOptions(g, p, card);
  const n = hexArcanaNum(card),
    pl = g.players[p],
    en = g.players[1 - p],
    all = hexAll(g).filter(
      (c) => hexSpellTargetable(c) && (c.owner === p || !hexProtectedFromSpecial(g, c)),
    ),
    mine = all.filter((c) => c.owner === p),
    enemy = all.filter((c) => c.owner !== p),
    empty = pl.board.flatMap((c, slot) => (c ? [] : [slot])),
    one = (list) => list.map((c) => ({ label: hexName(c), target: c.uid }));
  switch (n) {
    case 1:
      return mine.flatMap((c, i) =>
        mine.slice(i + 1).map((d) => ({
          label: hexName(c) + " ↔ " + hexName(d),
          target: c.uid,
          other: d.uid,
        })),
      );
    case 2:
    case 3:
      return one(enemy);
    case 4:
      return one(pl.discard.filter((c) => hexType(c, "Creature")));
    case 5:
    case 9:
    case 16:
      return one(mine);
    case 29:
      return hexTurnNumber(g) >= 3 ? [{ label: "Cast " + hexName(card) }] : [];
    case 6:
    case 11:
    case 18:
    case 22:
    case 24:
    case 25:
    case 27:
      return [{ label: "Cast " + hexName(card) }];
    case 7:
      return one(mine.filter((c) => c.hp < c.maxHp));
    case 8:
      return enemy.flatMap((c) =>
        empty.map((slot) => ({
          label:
            hexName(c) +
            " → " +
            (slot < hexColumns(g) ? "Front" : "Back") +
            " " +
            ((slot % hexColumns(g)) + 1),
          target: c.uid,
          slot,
        })),
      );
    case 10:
      return all.flatMap((c) =>
        empty
          .filter((slot) => hexNum(c) !== 8 || slot < hexColumns(g))
          .map((slot) => ({
            label: "Copy " + hexName(c) + " → slot " + (slot + 1),
            target: c.uid,
            slot,
          })),
      );
    case 12:
      return [
        ...g.players.flatMap((pl, owner) =>
          pl.artifacts.filter(Boolean).map((c) => ({
            label: "Destroy " + hexName(c),
            artifact: c.uid,
            side: owner,
          })),
        ),
        ...hexAll(g)
          .filter((c) => c.eq)
          .map((c) => ({
            label: "Destroy " + hexName(c.eq),
            target: c.uid,
            equipment: true,
          })),
      ];
    case 13:
      return g.players.flatMap((pl, side) =>
        pl.hand.length
          ? [
              {
                label: side === p ? "Discard from your hand" : "Opponent discards",
                side,
              },
            ]
          : [],
      );
    case 14:
    case 17:
    case 21:
      return one(all);
    case 15:
      return one(mine);
    case 19:
      return [
        ...one(all).map((o) => ({
          ...o,
          mode: "damage",
          label: "Deal 1 · " + o.label,
        })),
        ...one(all.filter((c) => c.hp < c.maxHp)).map((o) => ({
          ...o,
          mode: "heal",
          label: "Heal 1 · " + o.label,
        })),
        { label: "Draw 1 card", mode: "draw" },
      ];
    case 20:
      return en.board.flatMap((c, slot) =>
        c ? [] : [{ label: "Trap enemy slot " + (slot + 1), slot, side: 1 - p }],
      );
    case 23:
      return en.hand.map((c) => ({
        label: "Discard " + hexName(c),
        discard: c.uid,
      }));
    case 26: {
      const opts = [];
      for (let i = 0; i < all.length; i++)
        for (let j = i + 1; j < all.length; j++)
          opts.push({
            label: hexName(all[i]) + " & " + hexName(all[j]),
            target: all[i].uid,
            other: all[j].uid,
          });
      return opts.length ? opts : mine.length ? [{ label: "Flip the coin" }] : [];
    }
    case 28:
      return pl.deck.map((c) => ({ label: "Take " + hexName(c), take: c.uid }));
    default:
      return [];
  }
}
function hexArcanaTarget(
  g,
  p,
  uid,
  fn,
  source = g.effectSource,
  harmful = p !== hexFind(g, uid)?.owner,
) {
  const c = hexFind(g, uid);
  return c && hexSpellTargetable(c) && hexAffect(g, p, c, () => fn(c), true, source, harmful);
}
function hexArcanaKill(g, c, countsLoss = true) {
  if (!c) return;
  c.lastCombat = false;
  c.hp = 0;
  for (const d of hexDeaths(g, countsLoss ? [] : [c.uid]))
    if (g.winner === null) hexDeathTriggers(g, d);
}
function hexArcanaDamage(g, p, uid, amount, source, spell = false) {
  if (spell) amount += g.players[p].artifacts.filter((a) => a && hexArcanaNum(a) === 33).length;
  const hit = (c) =>
    hexDamage(g, [{ target: c.uid, amount, source, special: spell, wardChecked: true }]);
  if (spell) return hexArcanaTarget(g, p, uid, hit, source, true);
  return hexAffect(g, p, hexFind(g, uid), () => hit(hexFind(g, uid)), false, source, true);
}
function hexArcanaRecover(g, p, count, spells = false) {
  const pl = g.players[p],
    pool = pl.discard.filter((c) => !spells || hexType(c, "Spell"));
  if (!pool.length || count < 1) return;
  hexAsk(
    g,
    p,
    "Return a card from discard",
    pool.map((c) => ({
      label: hexName(c),
      task: hexArcanaTask(p, "recover", { uid: c.uid, count, spells }),
    })),
  );
}
function hexArcanaDiscardChoice(g, p, count = 1) {
  const pl = g.players[p];
  if (!pl.hand.length) return;
  hexAsk(
    g,
    p,
    "Choose a card to discard",
    pl.hand.map((c) => ({
      label: hexName(c),
      task: hexArcanaTask(p, "discard", { uid: c.uid, count }),
    })),
    false,
    true,
  );
}
function hexArcanaSearch(g, p, spells = false) {
  const pl = g.players[p];
  hexAsk(
    g,
    p,
    "Search your deck",
    pl.deck
      .filter((c) => !spells || hexType(c, "Spell"))
      .map((c) => ({
        label: hexName(c),
        task: hexArcanaTask(p, "search", { uid: c.uid }),
      })),
  );
}
function hexArcanaDraw(g, p, c) {
  for (const seer of g.players[p].board.filter((c) => c && hexArcanaNum(c) === 43))
    g.tasks.push(hexArcanaTask(p, "seer", { source: seer }));
  for (const [owner, pl] of g.players.entries())
    for (const a of pl.artifacts.filter((c) => c && hexArcanaNum(c) === 34)) {
      a.displacement = (a.displacement || 0) + 1;
      if (a.displacement >= 5) {
        a.displacement -= 5;
        g.tasks.push(hexArcanaTask(owner, "portal", { source: a.uid }));
      }
    }
}
function hexArcanaCast(g, p, card, o, copied = false) {
  if (copied) return;
  for (const c of g.players[p].board.filter(Boolean)) {
    const n = hexArcanaNum(c);
    if (n === 36) hexBuff(g, c, 1);
    if (n === 47) g.tasks.push(hexArcanaTask(p, "orator", { source: c.uid }));
  }
  for (const a of g.players[p].artifacts.filter((c) => c && hexArcanaNum(c) === 32))
    g.tasks.push(hexArcanaTask(p, "liquid", { source: a.uid }));
  for (const uid of [o.target, o.other].filter(Boolean)) {
    const c = hexFind(g, uid);
    if (c?.eq && hexArcanaNum(c.eq) === 31)
      g.tasks.push(hexArcanaTask(c.owner, "mirror", { card, option: o, original: uid }));
  }
}
function hexArcanaEntry(g, c) {
  const n = hexArcanaNum(c),
    p = c.owner;
  if (n === 38) hexDraw(g, p);
  if (n === 39) hexArcanaRecover(g, p, 1, true);
  if (n === 47) hexArcanaSearch(g, p, true);
  if (hexHasType(c, "Mage"))
    for (const a of hexAll(g).filter(
      (a) => a.uid !== c.uid && a.owner === p && hexArcanaNum(a) === 45,
    )) {
      a.attackBonus = (a.attackBonus || 0) + 1;
      hexShield(g, a, 1);
    }
  const traps = g.traps || [];
  for (const trap of traps.filter((t) => t.side === p && t.slot === c.slot && t.until >= g.turn)) {
    g.traps = g.traps.filter((t) => t !== trap);
    hexDamage(g, [{ target: c.uid, amount: 10, source: trap.source, special: true }]);
  }
}
function hexArcanaDeath(g, c) {
  const n = hexArcanaNum(c);
  if (n === 46) g.tasks.push(hexArcanaTask(c.owner, "rhodovan", { uid: c.uid }));
  if (hexHasType(c, "Mage"))
    for (const owner of (g.arcanaDeathObservers || []).filter((owner) => owner === c.owner))
      g.tasks.push({ kind: "draw", owner });
}
function hexArcanaHit(g, e) {
  if (hexArcanaNum(e.source) === 41 && hexFind(g, e.target)) hexArcanaKill(g, hexFind(g, e.target));
  if (e.combat && hexArcanaNum(e.targetSnapshot) === 42) hexDraw(g, e.targetSnapshot.owner);
}
function hexArcanaAttack(g, c) {
  if (hexArcanaNum(c) !== 40) return;
  const pl = g.players[c.owner];
  hexAsk(
    g,
    c.owner,
    "Feverish Academic · discard a Spell for +2 Attack?",
    pl.hand
      .filter((c) => hexType(c, "Spell"))
      .map((d) => ({
        label: "Discard " + hexName(d),
        task: hexArcanaTask(c.owner, "academic", { source: c.uid, uid: d.uid }),
      })),
    true,
  );
}
function hexArcanaEnd(g) {
  const sacrifices = hexAll(g).filter((c) => c.sacrificeAtEnd <= g.turn);
  for (const c of sacrifices) c.hp = 0;
  for (const dead of hexDeaths(g)) if (g.winner === null) hexDeathTriggers(g, dead);
  for (const c of hexAll(g).filter((c) => c.control && c.control.until <= g.turn)) {
    const ctrl = c.control,
      owner = ctrl.owner;
    g.players[c.owner].board[c.slot] = null;
    c.owner = owner;
    c.slot = ctrl.slot;
    delete c.control;
    if (!g.players[owner].board[c.slot]) g.players[owner].board[c.slot] = c;
    else {
      if (c.eq) g.players[owner].discard.push(c.eq);
      c.eq = null;
      hexResetInstance(c);
      if (hexHasType(c, "Summon")) hexRemoveFromGame(g, c);
      else g.players[owner].discard.push(c);
    }
  }
  g.traps = (g.traps || []).filter((t) => t.until > g.turn);
}
function hexArcanaSpell(g, p, card, o) {
  if (hexFoundation(card) === 24) {
    if (!g.players[o.side].planes[o.slot].locked) hexSetPlane(g, o.side, o.slot, { id: "FD-025" });
    return;
  }
  if (hexElderNum(card)) return hexElderSpell(g, p, card, o);
  const n = hexArcanaNum(card),
    pl = g.players[p],
    en = g.players[1 - p],
    target = (fn, harmful = ![1, 5, 7, 9, 10, 14, 17].includes(n)) =>
      hexArcanaTarget(g, p, o.target, fn, card, harmful),
    grant = (c, id, until = g.turn) => (c.grants || (c.grants = [])).push({ id, until });
  switch (n) {
    case 1:
      target((c) =>
        hexArcanaTarget(g, p, o.other, (d) => {
          if (c.owner === p && d.owner === p) hexSwap(g, p, c.slot, d.slot);
        }),
      );
      break;
    case 2:
      hexArcanaDamage(g, p, o.target, 2, card, true);
      break;
    case 3:
      target((c) => hexReturn(g, c));
      break;
    case 4: {
      const i = pl.discard.findIndex((c) => c.uid === o.target && hexType(c, "Creature"));
      if (i >= 0) {
        const c = pl.discard.splice(i, 1)[0];
        hexResetInstance(c);
        pl.hand.push(c);
      }
      break;
    }
    case 5:
      target((c) => grant(c, "sprint"));
      break;
    case 6: {
      const top = pl.deck.slice(0, 3);
      g.tasks.unshift(
        hexArcanaTask(p, "foresight", {
          ids: top.map((c) => c.uid),
          order: [],
        }),
      );
      break;
    }
    case 7:
      target((c) => hexHeal(g, c, 2));
      break;
    case 8:
      target((c) => {
        if (c.owner === p || pl.board[o.slot]) return;
        c.originalOwner = hexOriginalOwner(c);
        const old = { owner: c.owner, slot: c.slot, until: g.turn };
        g.players[c.owner].board[c.slot] = null;
        c.owner = p;
        c.slot = o.slot;
        c.control = old;
        pl.board[c.slot] = c;
        grant(c, "sprint");
      });
      break;
    case 9:
      target((c) => hexShield(g, c, 3));
      break;
    case 10:
      target((c) => {
        if (pl.board[o.slot]) return;
        const copy = {
          uid: "hc-" + ++g.serial,
          id: c.id,
          owner: p,
          originalOwner: p,
          spent: {},
          summoned: true,
        };
        hexExecute(g, {
          kind: "play",
          owner: p,
          card: copy,
          option: { slot: o.slot },
        });
        if (hexFind(g, copy.uid)) {
          (copy.grants || (copy.grants = [])).push({
            id: "sprint",
            until: g.turn,
          });
          copy.sacrificeAtEnd = g.turn;
        }
      });
      break;
    case 11:
      hexDraw(g, p, 2);
      break;
    case 12:
      if (o.equipment) {
        const c = hexFind(g, o.target);
        if (c?.eq) {
          hexVisualEvent(g, "destroy", hexVisualCard(c.eq));
          g.players[c.owner].discard.push(c.eq);
          c.eq = null;
        }
      } else {
        const a = hexArtifact(g, o.artifact);
        if (a) {
          const ap = g.players[a.owner];
          hexVisualEvent(g, "destroy", hexVisualCard(a));
          ap.artifacts[ap.artifacts.indexOf(a)] = null;
          ap.discard.push(a);
        }
      }
      break;
    case 13:
      hexArcanaDiscardChoice(g, o.side);
      break;
    case 14:
      target((c) => grant(c, "ranged"));
      break;
    case 15:
      target((c) => {
        hexArcanaKill(g, c);
        if (g.winner === null) hexArcanaRecover(g, p, 2);
      });
      break;
    case 16:
      target((c) => (c.tauntUntil = hexNextOwnerEnd(g, p)));
      break;
    case 17:
      target((c) => hexBuff(g, c, 3));
      break;
    case 18:
      for (const c of pl.board.filter(Boolean)) {
        hexHeal(g, c, 1);
        hexShield(g, c, 1);
      }
      break;
    case 19:
      if (o.mode === "draw") hexDraw(g, p);
      else if (o.mode === "heal") target((c) => hexHeal(g, c, 1), false);
      else hexArcanaDamage(g, p, o.target, 1, card, true);
      break;
    case 20:
      (g.traps || (g.traps = [])).push({
        side: 1 - p,
        slot: o.slot,
        until: g.turn + 2,
        source: card,
      });
      break;
    case 21:
      target((c) => hexArcanaKill(g, c, false));
      break;
    case 22:
      g.untargeted = true;
      for (const c of hexAll(g)) {
        hexAffect(
          g,
          p,
          c,
          () => {
            c.mods.push({ maxHp: -1, until: g.turn });
            hexVisualEvent(g, "status", {
              ...hexVisualCard(c),
              text: "−1 MAX HP",
              positive: false,
            });
          },
          false,
          card,
          true,
        );
      }
      hexRefresh(g);
      for (const c of hexAll(g)) if (c.hp <= 0) hexArcanaKill(g, c);
      delete g.untargeted;
      break;
    case 23: {
      const c = hexDiscardFromHand(g, 1 - p, o.discard);
      if (c) en.discard.push(c);
      break;
    }
    case 24:
      for (const c of pl.board.filter(Boolean)) {
        hexShield(g, c, 1);
        c.reflectUntil = Math.max(c.reflectUntil || 0, g.turn + 1);
      }
      break;
    case 25:
      hexDraw(g, p, 3);
      hexArcanaDiscardChoice(g, p);
      break;
    case 26:
      if (hexRand(g) < 0.5) {
        hexLog(g, "In Fate’s Hands · Heads");
        target((c) => hexArcanaKill(g, c));
        if (g.winner === null)
          hexArcanaTarget(g, p, o.other, (c) => hexArcanaKill(g, c), card, true);
      } else {
        hexLog(g, "In Fate’s Hands · Tails");
        hexAsk(
          g,
          p,
          "Sacrifice a creature",
          pl.board.filter(Boolean).map((c) => ({
            label: hexName(c),
            task: hexArcanaTask(p, "sacrifice", { uid: c.uid }),
          })),
        );
      }
      break;
    case 27:
      for (let side = 0; side < 2; side++) {
        const player = g.players[side];
        player.discard.push(...player.hand);
        player.hand = [];
        hexDraw(g, side, 5);
      }
      break;
    case 28:
      hexArcanaExecute(g, hexArcanaTask(p, "search", { uid: o.take }));
      break;
    case 29: {
      const destroyed = [];
      g.untargeted = true;
      for (const c of hexAll(g))
        hexAffect(
          g,
          p,
          c,
          () => {
            c.hp = 0;
            destroyed.push(c.uid);
          },
          false,
          card,
          true,
        );
      for (const c of hexDeaths(g, destroyed)) if (g.winner === null) hexDeathTriggers(g, c);
      delete g.untargeted;
      break;
    }
  }
}
function hexArcanaExecute(g, j) {
  const p = j.owner,
    pl = g.players[p],
    c = j.uid && hexFind(g, j.uid);
  switch (j.op) {
    case "spell":
      hexArcanaSpell(g, p, j.card, j.option);
      hexLog(g, hexName(j.card) + " resolved.");
      if (!j.copied) pl.discard.push(j.card);
      break;
    case "recover": {
      const i = pl.discard.findIndex((c) => c.uid === j.uid);
      if (i >= 0) {
        const c = pl.discard.splice(i, 1)[0];
        hexResetInstance(c);
        pl.hand.push(c);
        hexArcanaRecover(g, p, j.count - 1, j.spells);
      }
      break;
    }
    case "discard": {
      const c = hexDiscardFromHand(g, p, j.uid);
      if (c) {
        pl.discard.push(c);
        if (j.count > 1) hexArcanaDiscardChoice(g, p, j.count - 1);
      }
      break;
    }
    case "search": {
      const i = pl.deck.findIndex((c) => c.uid === j.uid);
      if (i >= 0) pl.hand.push(pl.deck.splice(i, 1)[0]);
      pl.deck = hexShuffle(g, pl.deck);
      break;
    }
    case "seer":
      hexAsk(
        g,
        p,
        "Seer of the Realms · deal 1 damage",
        hexAll(g).map((c) => ({
          label: hexName(c),
          task: hexArcanaTask(p, "seerHit", { uid: c.uid, source: j.source }),
        })),
      );
      break;
    case "seerHit":
      hexArcanaDamage(g, p, j.uid, 1, j.source);
      break;
    case "liquid":
      if (hexArtifact(g, j.source))
        hexAsk(
          g,
          p,
          "Liquid Magic · +1 Attack",
          hexAll(g).map((c) => ({
            label: hexName(c),
            task: hexArcanaTask(p, "liquidBuff", { uid: c.uid }),
          })),
        );
      break;
    case "liquidBuff":
      if (c) hexAffect(g, p, c, () => hexBuff(g, c, 1));
      break;
    case "orator":
      // There is no target or payment decision; settle the triggered heal immediately.
      if (hexFind(g, j.source))
        for (const mage of hexAll(g).filter((c) => hexHasType(c, "Mage"))) hexHeal(g, mage, 1);
      break;
    case "healMages":
      for (const c of hexAll(g).filter((c) => hexHasType(c, "Mage"))) hexHeal(g, c, 1);
      break;
    case "portal": {
      if (!hexArtifact(g, j.source)) break;
      const opts = hexAll(g).flatMap((c) =>
        g.players[c.owner].board.flatMap((v, slot) =>
          !v && (hexNum(c) !== 8 || slot < hexColumns(g))
            ? [
                {
                  label: hexName(c) + " → slot " + (slot + 1),
                  task: hexArcanaTask(p, "move", { uid: c.uid, slot }),
                },
              ]
            : [],
        ),
      );
      hexAsk(g, p, "Displacement · move a creature", opts);
      break;
    }
    case "move":
      if (c && !g.players[c.owner].board[j.slot])
        hexAffect(g, p, c, () => {
          g.players[c.owner].board[c.slot] = null;
          c.slot = j.slot;
          g.players[c.owner].board[c.slot] = c;
          hexArcanaEntryTrap(g, c);
        });
      break;
    case "mirror": {
      if (!hexArcanaNum(j.card)) {
        if (hexNum(j.card) === 33) {
          const targets = hexAll(g).filter(
            (c) =>
              hexSpellTargetable(c) &&
              c.uid !== j.original &&
              (j.option.mode === "heal"
                ? c.owner === p && c.hp < c.maxHp
                : c.owner !== p && c.slot < hexColumns(g) && !hexProtectedFromSpecial(g, c)),
          );
          hexAsk(
            g,
            p,
            "Mirror Plate · copy Prismatic Echo",
            targets.map((c) => ({
              label: hexName(c),
              task: hexArcanaTask(p, "prismCopy", {
                card: j.card,
                uid: c.uid,
                mode: j.option.mode,
              }),
            })),
          );
        }
        break;
      }
      const opts = hexArcanaOptions(g, p, j.card)
        .filter((o) => o.target && o.target !== j.original)
        .map((o) => ({
          label: o.label,
          task: hexArcanaTask(p, "spell", {
            card: { ...j.card, owner: p },
            option: o,
            copied: true,
          }),
        }));
      hexAsk(g, p, "Mirror Plate · choose a target for the copy", opts);
      break;
    }
    case "prismCopy":
      if (j.mode === "heal") hexArcanaTarget(g, p, j.uid, (c) => hexHeal(g, c, 2));
      else hexArcanaDamage(g, p, j.uid, 1, j.card, true);
      break;
    case "academic": {
      const source = hexFind(g, j.source),
        cost = hexDiscardFromHand(g, p, j.uid);
      if (source && cost) {
        pl.discard.push(cost);
        source.attackBonus = (source.attackBonus || 0) + 2;
      }
      break;
    }
    case "rhodovan": {
      const i = pl.discard.findIndex((c) => c.uid === j.uid);
      if (i >= 0) {
        const c = pl.discard.splice(i, 1)[0];
        hexResetInstance(c);
        pl.hand.push(c);
      }
      break;
    }
    case "sacrifice":
      if (c) hexArcanaKill(g, c);
      break;
    case "foresight": {
      const ids = j.ids.filter(
        (uid) => pl.deck.some((c) => c.uid === uid) && !j.order.includes(uid),
      );
      if (!ids.length) {
        const cards = j.order.map((uid) => pl.deck.find((c) => c.uid === uid)).filter(Boolean);
        pl.deck = cards.concat(pl.deck.filter((c) => !j.ids.includes(c.uid)));
        break;
      }
      hexAsk(
        g,
        p,
        "Foresight · choose next card on top",
        ids.map((uid) => ({
          label: hexName(pl.deck.find((c) => c.uid === uid)),
          task: hexArcanaTask(p, "foresight", {
            ids: j.ids,
            order: j.order.concat(uid),
          }),
        })),
      );
      break;
    }
  }
}
function hexArcanaEntryTrap(g, c) {
  for (const trap of (g.traps || []).filter(
    (t) => t.side === c.owner && t.slot === c.slot && t.until >= g.turn,
  )) {
    g.traps = g.traps.filter((t) => t !== trap);
    hexDamage(g, [{ target: c.uid, amount: 10, source: trap.source, special: true }]);
  }
}
/* Spell choices use public targets and the bot's own hand/deck, never hidden draw order. */
function hexArcanaBotScore(g, p, card, o) {
  if (hexElderNum(card)) return hexElderBotSpell(g, p, card, o);
  const n = hexArcanaNum(card),
    t = o.target && hexFind(g, o.target),
    friend = t?.owner === p,
    value = t ? hexStats(g, t).attack + t.hp * 0.5 : 0;
  switch (n) {
    case 1:
      return -1;
    case 2:
      return t ? 3 + (t.hp + (t.shield || 0) <= 2 ? 12 : 0) : 0;
    case 3:
    case 8:
      return value + 5;
    case 5:
      return hexCanUseQuicken(g, p, t) ? 5 : -1;
    case 7:
      return t ? Math.min(2, t.maxHp - t.hp) * 4 : 0;
    case 9:
    case 16:
      return friend ? 6 : -1;
    case 10:
      return value + 6;
    case 12:
      return (o.equipment ? hexFind(g, o.target)?.owner : hexArtifact(g, o.artifact)?.owner) === p
        ? -1
        : 8;
    case 13:
      return o.side === p ? -1 : 5;
    case 14:
      return friend ? 4 : -1;
    case 15:
      return t ? 3 - value : -1;
    case 17:
      return friend ? 7 : -1;
    case 19:
      return o.mode === "draw" ? 6 : o.mode === "damage" ? (friend ? -1 : 7) : friend ? 5 : -1;
    case 21:
      return friend ? -1 : value + 8;
    case 22:
      return hexAll(g).reduce((v, c) => v + (c.owner === p ? -1 : 1), 0);
    case 26:
      return friend ? -1 : 7;
    case 27:
      return Math.max(0, 5 - g.players[p].hand.length) * 3;
    case 28: {
      const c = g.players[p].deck.find((c) => c.uid === o.take);
      return c ? hexBotCardValue(g, c) : 0;
    }
    case 29:
      return hexAll(g).reduce(
        (v, c) => v + (c.owner === p ? -1 : 1) * (hexStats(g, c).attack + c.hp),
        0,
      );
    default:
      return 5;
  }
}
function hexArcanaChoiceScore(g, o) {
  const j = o.task,
    p = j.owner,
    c = hexCardUid(g, j.uid),
    t = j.uid && hexFind(g, j.uid);
  if (j.op === "seerHit") return t ? (t.owner === p ? -30 : 5 + (t.hp <= 1 ? 15 : 0)) : 0;
  if (j.op === "liquidBuff") return t?.owner === p ? 5 + hexStats(g, t).attack : -10;
  if (j.op === "sacrifice") return t ? 20 - t.hp - hexStats(g, t).attack : 0;
  if (j.op === "search" || j.op === "recover" || j.op === "foresight")
    return c ? hexBotCardValue(g, c) : 0;
  if (j.op === "discard") return c ? -hexBotCardValue(g, c) : 0;
  if (j.op === "spell") return hexArcanaBotScore(g, p, j.card, j.option);
  return 2;
}
