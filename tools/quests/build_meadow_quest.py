"""Author the Meadow quest with the project's existing typed Resource classes."""

from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[2]


class Resources:
    def __init__(self):
        self.external = {}
        self.parts = []

    def ext(self, key, path, kind="Script"):
        self.external[key] = (path, kind)
        return f'ExtResource("{key}")'

    def sub(self, identifier, script, **fields):
        body = "\n".join(f"{name} = {value}" for name, value in fields.items())
        self.parts.append(
            f'[sub_resource type="Resource" id="{identifier}"]\nscript = {script}\n{body}\n'
        )
        return f'SubResource("{identifier}")'

    def write(self, path, script, **fields):
        header = f'[gd_resource type="Resource" load_steps={1 + len(self.external) + len(self.parts)} format=3]\n'
        external = [
            f'[ext_resource type="{kind}" path="res://{path}" id="{key}"]'
            for key, (path, kind) in self.external.items()
        ]
        body = "\n".join(f"{name} = {value}" for name, value in fields.items())
        (ROOT / path).write_text(
            header
            + "\n"
            + "\n".join(external)
            + "\n\n"
            + "\n".join(self.parts)
            + f"\n[resource]\nscript = {script}\n{body}\n"
        )


def text(value):
    return json.dumps(value, ensure_ascii=False)


def array(kind, values):
    return f'Array[{kind}]([{", ".join(values)}])'


def build_quest():
    r = Resources()
    quest = r.ext("quest", "Scripts/Quests/QuestResource.gd")
    objective = r.ext("objective", "Scripts/Quests/QuestObjective.gd")
    reward = r.ext("reward", "Scripts/Quests/Rewards/QuestReward.gd")
    xp = r.ext("xp", "Scripts/Quests/Rewards/QuestReward.XP.gd")
    objectives = []
    for number, (flag, description) in enumerate(
        [
            (
                "MEADOW_MET_LIORA",
                "Speak to Liora beside the flowers in the eastern meadow.",
            ),
            (
                "MEADOW_INVITED_ROWAN",
                "Deliver Liora's invitation to Captain Rowan by the steps.",
            ),
            ("MEADOW_ENCORE_FINISHED", "Return to Liora and ask to see her encore."),
        ]
    ):
        objectives.append(
            r.sub(
                f"Objective{number}",
                objective,
                id=text(flag.lower()),
                flag=text(flag),
                description=text(description),
            )
        )
    prize = r.sub("RewardXP", xp, amount="25")
    r.write(
        "Resources/Quests/meadow_encore.tres",
        quest,
        id=text("MEADOW_ENCORE"),
        title=text("A Dance for the Meadow"),
        description=text(
            "Help a performer invite a tired sentry to an evening of music. Speak to Captain Rowan to begin."
        ),
        objectives=array(objective, objectives),
        rewards=array(reward, [prize]),
    )


def build_dialog(soldier):
    r = Resources()
    dialog = r.ext("dialog", "Scripts/Dialog/DialogResource.gd")
    entry = r.ext("entry", "Scripts/Dialog/DialogEntry.gd")
    option = r.ext("option", "Scripts/Dialog/DialogOption.gd")
    condition = r.ext("condition", "Scripts/Dialog/DialogCondition.gd")
    task = r.ext("task", "Scripts/Quests/Tasks/Task.gd")
    quest_task = r.ext("quest_task", "Scripts/Quests/Tasks/QuestTask.gd")
    flag_task = r.ext("flag_task", "Scripts/Quests/Tasks/FlagTask.gd")
    flag = r.ext("flag", "Scripts/Flags/FlagData.gd")
    action = r.ext("action", "Scripts/Dialog/Actions/DialogAction.gd")
    start_action = r.ext("start", "Scripts/Dialog/Actions/StartQuestDialogAction.gd")
    active = r.sub("Active", quest_task, quest_name="3", quest_state="1")
    complete = r.sub("Complete", quest_task, quest_name="3", quest_state="2")
    flags = {}
    for key in [4, 5]:
        expected = r.sub(f"Expected{key}", flag, key=str(key), value="true")
        flags[key] = r.sub(f"Flag{key}", flag_task, flag=expected)
    conditions = []

    def when(id, target, priority, tasks):
        conditions.append(
            r.sub(
                id,
                condition,
                logic="1",
                next=text(target),
                priority=str(priority),
                tasks=array(task, tasks),
            )
        )

    entries = []

    def line(id, lines, options=None, set_flags=None):
        entries.append(
            r.sub(
                id,
                entry,
                id=text(id),
                text=array("String", [text(t) for t in lines]),
                state="0" if not entries else "2",
                options=array(option, options or []),
                flags=array("int", [str(n) for n in set_flags or []]),
            )
        )

    if soldier:
        start = r.sub("AcceptAction", start_action, quest_name="3")
        accept = r.sub(
            "Accept",
            option,
            text=text("I'll check on her."),
            next=text("accepted"),
            actions=array(action, [start]),
        )
        decline = r.sub("Decline", option, text=text("Perhaps later."), next=text(""))
        line(
            "offer",
            [
                "Captain Rowan rests a gauntleted hand on his sword.",
                "Liora was going to dance for the watch, but I haven't seen her all morning. Would you check on her? She's beside the flowers, east of here.",
            ],
            [accept, decline],
        )
        line(
            "accepted",
            [
                "Thank you. A little music would do this old watch some good. Look for her coral dress beside the eastern flower patch."
            ],
        )
        line(
            "reminder",
            [
                "Liora should be beside the flowers in the eastern meadow. Would you see how her preparations are going?"
            ],
        )
        line(
            "deliver",
            [
                "An invitation from Liora? I thought she had forgotten this old soldier!",
                "Tell her I'll join her after my watch. And thank you for delivering it.",
            ],
            set_flags=[5],
        )
        line(
            "invited",
            [
                "Please tell Liora I'll be there after my watch. She needn't worry about an empty audience."
            ],
        )
        line(
            "after",
            [
                "I heard the music from here. You've given us both something to look forward to. Well done, friend."
            ],
        )
        when("After", "after", 100, [complete])
        when("Invited", "invited", 30, [active, flags[5]])
        when("Deliver", "deliver", 20, [active, flags[4]])
        when("Reminder", "reminder", 10, [active])
        npc, title = "CaptainRowan", "Captain Rowan"
        path = "Resources/Dialog/npc_captain_rowan.tres"
    else:
        perform = r.sub(
            "Perform",
            option,
            text=text("I'd love to see your encore."),
            next=text("finish"),
            flags=array("int", ["6"]),
        )
        later = r.sub(
            "Later", option, text=text("I'll come back in a moment."), next=text("")
        )
        line(
            "before",
            [
                "Liora turns through a few graceful steps, her ribbons catching the breeze.",
                "I'm preparing a little dance for the watch. Captain Rowan is near the steps if you'd like to help.",
            ],
        )
        line(
            "invite",
            [
                "Captain Rowan sent you? I thought he'd be far too busy for a performance.",
                "Would you invite him for me? Tell him I'll save a dance until his watch is over.",
            ],
            set_flags=[4],
        )
        line(
            "waiting",
            [
                "Would you take my invitation to Captain Rowan by the steps? I'll keep rehearsing here."
            ],
        )
        line(
            "ready",
            [
                "He'll come after his watch? Wonderful! Thank you for asking him.",
                "While we wait, would you like to see the encore I've been practicing?",
            ],
            [perform, later],
        )
        line(
            "finish",
            [
                "Liora traces a bright circle through the flowers, her skirts following the rhythm of a melody carried on the wind.",
                "Thank you for bringing a little company to the meadow. Quest complete: 25 XP.",
            ],
        )
        line(
            "after",
            [
                "There is always room for one more in the audience. Thank you again for helping us."
            ],
        )
        when("After", "after", 100, [complete])
        when("Ready", "ready", 20, [active, flags[5]])
        when("Waiting", "waiting", 10, [active, flags[4]])
        when("Invite", "invite", 5, [active])
        npc, title = "Liora", "Liora"
        path = "Resources/Dialog/npc_liora.tres"
    r.write(
        path,
        dialog,
        npc_id=text(npc),
        npc_name=text(title),
        entries=array(entry, entries),
        conditions=array(condition, conditions),
    )


def build_flags():
    path = ROOT / "Resources/flags.tres"
    content = path.read_text()
    if 'id="Meadow4"' in content:
        return
    content = content.replace("load_steps=7", "load_steps=10")
    extra = "\n".join(
        f'[sub_resource type="Resource" id="Meadow{key}"]\nscript = ExtResource("1_pc7o2")\nkey = {key}\nvalue = false\n'
        for key in [4, 5, 6]
    )
    content = content.replace("[resource]", extra + "\n[resource]")
    content = content.replace(
        'SubResource("Resource_jpew3")])',
        'SubResource("Resource_jpew3"), SubResource("Meadow4"), SubResource("Meadow5"), SubResource("Meadow6")])',
    )
    path.write_text(content)


if __name__ == "__main__":
    build_quest()
    build_dialog(True)
    build_dialog(False)
    build_flags()
