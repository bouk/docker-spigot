#!/bin/bash
set -e
sudo usermod --uid $UID minecraft
sudo groupmod --gid $GUID minecraft

if [ ! -e $SPIGOT_HOME/eula.txt ]; then
  if [ "$EULA" != "" ]; then
    echo "# Generated via Docker on $(date)" > $SPIGOT_HOME/eula.txt
    echo "eula=$EULA" >> $SPIGOT_HOME/eula.txt
  else
    echo "*****************************************************************"
    echo "*****************************************************************"
    echo "** To be able to run spigot you need to accept minecrafts EULA **"
    echo "** see https://account.mojang.com/documents/minecraft_eula     **"
    echo "** include -e EULA=true on the docker run command              **"
    echo "*****************************************************************"
    echo "*****************************************************************"
    exit
  fi
fi

#only build if jar file does not exist
if [ ! -f $SPIGOT_HOME/spigot.jar ]; then
  echo "Building spigot jar file, be patient"
  mkdir -p /tmp/buildSpigot
  cd /tmp/buildSpigot
  wget https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar
  HOME=/tmp/buildSpigot java -jar BuildTools.jar --rev $REV
  cp /tmp/buildSpigot/Spigot/Spigot-Server/target/spigot-*.jar $SPIGOT_HOME/spigot.jar
  rm -rf /tmp/buildSpigot
  mkdir -p $SPIGOT_HOME/plugins
fi

if [ -n "$WORLDBORDER" ]; then
  if [ "$WORLDBORDER" = "true" ]; then
    echo "Downloading WorldBorder..."
    wget -O $SPIGOT_HOME/plugins/WorldBorder.jar https://dev.bukkit.org/projects/worldborder/files/latest
  else
    echo "Removing WorldBorder..."
    rm -f $SPIGOT_HOME/plugins/WorldBorder.jar
  fi
fi

if [ -n "$DYNMAP" ]; then
  if [ "$DYNMAP" = "true" ]; then
    echo "Downloading Dynmap..."
    wget -O $SPIGOT_HOME/plugins/dynmap-HEAD.jar http://mikeprimm.com/dynmap/builds/dynmap/dynmap-HEAD.jar
    wget -O $SPIGOT_HOME/plugins/dynmap-mobs-HEAD.jar http://mikeprimm.com/dynmap/builds/dynmap-mobs/dynmap-mobs-HEAD.jar
    if [ -n "$ESSENTIALS" ]; then
      if [ "$ESSENTIALS" = "true" ]; then
        echo "Downloading Dynmap Essentials..."
        wget -O $SPIGOT_HOME/plugins/Dynmap-Essentials-HEAD.jar http://mikeprimm.com/dynmap/builds/Dynmap-Essentials/Dynmap-Essentials-HEAD.jar
      else
        echo "Removing Dynmap Essential..."
        rm -f $SPIGOT_HOME/plugins/Dynmap-Essentials-HEAD.jar
      fi
    fi
  else
    echo "Removing Dynmap..."
    rm -f $SPIGOT_HOME/plugins/dynmap-HEAD.jar
    rm -f $SPIGOT_HOME/plugins/dynmap-mobs-HEAD.jar
    rm -f $SPIGOT_HOME/plugins/Dynmap-Essentials-HEAD.jar
  fi
fi

if [ -n "$ESSENTIALS" ]; then
  if [ "$ESSENTIALS" = "true" ]; then
    echo "Downloading Essentials..."
    wget -O $SPIGOT_HOME/plugins/Essentials-2.x-SNAPSHOT.jar https://hub.spigotmc.org/jenkins/job/Spigot-Essentials/lastStableBuild/artifact/Essentials/target/Essentials-2.x-SNAPSHOT.jar
    if [ -n "$ESSENTIALSPROTECT" ]; then
      if [ "$ESSENTIALSPROTECT" = "true" ]; then
        echo "Downloading EssentialsProtect..."
        wget -O $SPIGOT_HOME/plugins/EssentialsProtect-2.x-SNAPSHOT.jar https://hub.spigotmc.org/jenkins/job/Spigot-Essentials/lastStableBuild/artifact/EssentialsProtect/target/EssentialsProtect-2.x-SNAPSHOT.jar
      else
        echo "Removing EssentialsProtect..."
        rm -f $SPIGOT_HOME/plugins/EssentialsProtect-2.x-SNAPSHOT.jar
      fi
      if [ -n "$ESSENTIALS_CREEPERBLOCKDMG" -a -f $SPIGOT_HOME/plugins/Essentials/config.yml ]; then
        echo "Setting creeper block damage to $ESSENTIALS_CREEPERBLOCKDMG..."
        sed -i "s/creeper-blockdamage: .*/creeper-blockdamage: $ESSENTIALS_CREEPERBLOCKDMG/" $SPIGOT_HOME/plugins/Essentials/config.yml
      fi
    fi
  else
    echo "Removing Essentials..."
    rm -f $SPIGOT_HOME/plugins/Essentials-2.x-SNAPSHOT.jar
    rm -f $SPIGOT_HOME/plugins/EssentialsProtect-2.x-SNAPSHOT.jar
  fi
fi

if [ -n "$CLEARLAG" ]; then
  if [ "$CLEARLAG" = "true" ]; then
    echo "Downloading ClearLag..."
    wget -O $SPIGOT_HOME/plugins/Clearlag.jar https://dev.bukkit.org/projects/clearlagg/files/latest
  else
    echo "Removing Clearlag..."
    rm -f $SPIGOT_HOME/plugins/Clearlag.jar
  fi
fi

if [ -n "$PERMISSIONSEX" ]; then
  if [ "$PERMISSIONSEX" = "true" ]; then
    echo "Downloading PermissionsEx..."
    wget -O $SPIGOT_HOME/plugins/PermissionsEx.jar https://dev.bukkit.org/projects/permissionsex/files/latest
  else
    echo "Removing PermissionsEx..."
    rm -f $SPIGOT_HOME/plugins/PermissionsEx.jar
  fi
fi

if [ ! -f $SPIGOT_HOME/ops.txt ]
then
    cp /usr/local/etc/minecraft/ops.txt $SPIGOT_HOME/
fi

if [ ! -f $SPIGOT_HOME/white-list.txt ]
then
    cp /usr/local/etc/minecraft/white-list.txt $SPIGOT_HOME/
fi

function setServerProp {
  local prop=$1
  local var=$2
  if [ -n "$var" ]; then
    echo "Setting $prop to $var"
    sed -i "/$prop\s*=/ c $prop=$var" $SPIGOT_HOME/server.properties
  fi
}

if [ ! -f $SPIGOT_HOME/server.properties ]
then
  cp /usr/local/etc/minecraft/server.properties $SPIGOT_HOME/

  setServerProp "motd" "$MOTD"
  setServerProp "level-name" "$LEVEL"
  setServerProp "level-seed" "$SEED"
  setServerProp "pvp" "$PVP"
  setServerProp "view-distance" "$VDIST"
  setServerProp "op-permission-level" "$OPPERM"
  setServerProp "allow-nether" "$NETHER"
  setServerProp "allow-flight" "$FLY"
  setServerProp "max-build-height" "$MAXBHEIGHT"
  setServerProp "spawn-npcs" "$NPCS"
  setServerProp "white-list" "$WLIST"
  setServerProp "spawn-animals" "$ANIMALS"
  setServerProp "hardcore" "$HC"
  setServerProp "online-mode" "$ONLINE"
  setServerProp "resource-pack" "$RPACK"
  setServerProp "difficulty" "$DIFFICULTY"
  setServerProp "enable-command-block" "$CMDBLOCK"
  setServerProp "max-players" "$MAXPLAYERS"
  setServerProp "spawn-monsters" "$MONSTERS"
  setServerProp "generate-structures" "$STRUCTURES"
  setServerProp "spawn-protection" "$SPAWNPROTECTION"
  setServerProp "max-tick-time" "$MAX_TICK_TIME"
  setServerProp "max-world-size" "$MAX_WORLD_SIZE"
  setServerProp "resource-pack-sha1" "$RPACK_SHA1"
  setServerProp "network-compression-threshold" "$NETWORK_COMPRESSION_THRESHOLD"

  if [ -n "$MODE" ]; then
    case ${MODE,,?} in
      0|1|2|3)
        ;;
      s*)
        MODE=0
        ;;
      c*)
        MODE=1
        ;;
      *)
        echo "ERROR: Invalid game mode: $MODE"
        exit 1
        ;;
    esac

    sed -i "/gamemode\s*=/ c gamemode=$MODE" $SPIGOT_HOME/server.properties
  fi
fi

if [ -n "$OPS" -a ! -e $SPIGOT_HOME/ops.txt.converted ]; then
  echo $OPS | awk -v RS=, '{print}' >> $SPIGOT_HOME/ops.txt
fi

if [ -n "$ICON" -a ! -e $SPIGOT_HOME/server-icon.png ]; then
  echo "Using server icon from $ICON..."
  # Not sure what it is yet...call it "img"
  wget -q -O /tmp/icon.img $ICON
  specs=$(identify /tmp/icon.img | awk '{print $2,$3}')
  if [ "$specs" = "PNG 64x64" ]; then
    mv /tmp/icon.img $SPIGOT_HOME/server-icon.png
  else
    echo "Converting image to 64x64 PNG..."
    convert /tmp/icon.img -resize 64x64! $SPIGOT_HOME/server-icon.png
  fi
fi

# change owner to minecraft
if [ "$SKIPCHMOD" != "true" ]; then
  sudo chown -R minecraft:minecraft $SPIGOT_HOME/
else
  echo "SKIPCHMOD option enabled. If you have access issue with your files, disable it"
fi

cd $SPIGOT_HOME/

# su - minecraft -c "/spigot_run.sh server java $JVM_OPTS -jar spigot.jar"
# Removing the call by minecraft because it does not have access to /proc
/spigot_run.sh server java $JVM_OPTS -jar spigot.jar

# fallback to root and run shell if spigot don't start/forced exit
bash
