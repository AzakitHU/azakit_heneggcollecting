LANGUAGE = 'en'

EGG = "egg" -- reward
MINEGG = 1 -- minimum egg / hen
MAXEGG = 2 -- maximum egg / hen
COOLDOWN = 300.0 -- sec / hen / player 300.0 = 5 minutes

Hen = {
    {
        henCoords = vector4(1450.2029, 1066.9233, 114.3340, 347.2474), -- x, y, z, heading
        hensettings = {
            Freezehen = false, -- Freeeze Hen
            Invincible = true, -- Invincible Hen
            BlockingOfNonTemporaryEvents = true, -- SetBlockingOfNonTemporaryEvents
        },
    },
    {
        henCoords = vector4(1446.9935, 1066.0626, 114.3418, 67.9827), -- x, y, z, heading
        hensettings = {
            Freezehen = false,
            Invincible = true,
            BlockingOfNonTemporaryEvents = true, 
        },
    },
}

Check = {
    EnableSkillCheck = true, -- OX_LIB Skill Check.
    ProcessTime = 5, -- second - Only used when EnableSkillCheck is false.
}

Webhook = ""
