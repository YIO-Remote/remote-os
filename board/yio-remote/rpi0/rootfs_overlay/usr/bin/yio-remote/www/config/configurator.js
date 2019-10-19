const SUPPORTED_ENTITIES = ["blind", "light", "media_player"];
const DEBUG_HOST = "10.2.1.217";

const UI_ELEMENTS = {
  integrations: ["intergrations"],
  entities: ["entities"],
  areas: ["areas", "areasArea"],
  advanced: ["configFile"],
  settings: ["settings"],
  profiles: ["ui_config.profiles", "toolEntities"],
  groups: ["ui_config.groups", "toolEntities"],
  pages: ["ui_config.pages"]
};

let socket;
let configObj;

function wsConnect(url) {
  socket = new WebSocket(url);
  console.log(`Connecting to host: "${host}"`);

  socket.onopen = function(e) {
    console.log("[open] Connection established");
    console.log("Sending auth request to server");
    socket.send(buildAuthPacket("0"));
  };

  socket.onmessage = function(event) {
    const messageJson = event.data;
    messageObj = JSON.parse(messageJson);
    console.log(`[message] Data received from server`);
    if (messageObj.type && messageObj.type === "auth_ok") {
      console.log("Sending configJson request to server");
      getConfig();
    }
    if (messageObj.type && messageObj.type === "config") {
      configObj = messageObj.config;
      parseConfigurationJson();
    }
  };

  socket.onclose = function(event) {
    if (event.wasClean) {
      console.log(`[close] Connection closed cleanly, code=${event.code} reason=${event.reason}`);
    } else {
      // e.g. server process killed or network down
      // event.code is usually 1006 in this case
      console.log("[close] Connection died");
    }
  };

  socket.onerror = function(error) {
    console.log(`[error] ${error.message}`);
  };
}

function getConfig() {
  socket.send(`{"type":"getconfig"}`);
}

function setConfig() {
  try {
    //Try parsing configuration. Fail on error
    let confJson = document.getElementById("configJsonTextBox").value;
    configObj = JSON.parse(confJson);
    socket.send(`{"type":"setconfig", "config":${confJson}}`);
    console.log("Config save requested");
    parseConfigurationJson();
  } catch (e) {
    alert(`Failed to save configuration with error: ${e.message}`);
    console.log(`Failed to save configuration with error: ${e.message}`);
  }
}

function buildAuthPacket(token) {
  return `{"type":"auth","token": "${token}"}`;
}

function uuidv4() {
  return ([1e7] + -1e3 + -4e3 + -8e3 + -1e11).replace(/[018]/g, c => (c ^ (crypto.getRandomValues(new Uint8Array(1))[0] & (15 >> (c / 4)))).toString(16));
}

function parseConfigurationJson() {
  if (configObj) displayJsonConfigText(configObj);
  if (configObj.areas) displayAreas(configObj.areas);
  if (configObj.entities) displayEntities(configObj.entities);
  if (configObj.integrations) displayIntegrations(configObj.integrations);
  if (configObj.settings) displaySettings(configObj.settings, configObj.ui_config);
  if (configObj.ui_config.groups) displayUiConfigGroups(configObj.ui_config, configObj.entities);
  if (configObj.ui_config.pages) displayUiConfigPages(configObj.ui_config);
  if (configObj.ui_config.profiles) displayUiConfigProfiles(configObj.ui_config, configObj.entities);
}

function setActiveUI(element) {
  const keys = Object.keys(UI_ELEMENTS);
  for (let key of keys) {
    for (let elmnt of UI_ELEMENTS[key]) {
      if (key === element) {
        setVisibilityOfId(elmnt, true);
      } else {
        setVisibilityOfId(elmnt, false);
      }
    }
  }
  if (element == "groups") {
  }
}

function setVisibilityOfId(id, visibility) {
  let element = document.getElementById(id);
  if (visibility) {
    element.style.display = "block";
  } else {
    element.style.display = "none";
  }
}

function displayJsonConfigText(confObj) {
  let confJson = JSON.stringify(confObj, null, 2);
  document.getElementById("configJsonTextBox").value = confJson;
}

function displayAreas(areas) {
  let innerHtml = "<h3>Configuration Areas</h3>";
  for (let area of areas) {
    innerHtml += `<div class="configItem"><b>${area.area}</b><a class="small">${area.bluetooth}</a></div>`;
  }
  document.getElementById("areas").innerHTML = innerHtml;
}

function displayEntities(entities) {
  let entityHtml = "<h3>Configuration Entities</h3>";
  let toolHtml = "<h3>Dragable Entities</h3>";
  let ulArray = [];

  for (let type of SUPPORTED_ENTITIES) {
    //entityHtml += `<h4>${type}</h4>`;
    //toolHtml += `<h4>${type}</h4>`;

    let ulID = `tool.entities.${type}`;
    ulArray.push(ulID);
    toolHtml += `<ul id="${ulID}" class="toolDragList">`;

    for (let entity of entities[type]) {
      toolHtml += `<li class="dragableItem" id="${entity.entity_id}"><b>${entity.friendly_name}</b> <a class="small">${entity.area}</a></li>`;
      entityHtml += `<div class="configItem"><b>${entity.friendly_name}</b> <a class="small">${entity.area}</a></div>`;
    }
    toolHtml += `</ul>`;
  }
  document.getElementById("entities").innerHTML = entityHtml;
  document.getElementById("toolEntities").innerHTML = toolHtml;

  for (ulID of ulArray) {
    makeDragableGroups(ulID);
  }
}

function displayIntegrations(integrations) {
  let innerHtml = "<h3>Integrations</h3>";

  const keys = Object.keys(integrations);

  for (let key of keys) {
    for (let integration of integrations[key].data) {
      innerHtml += `<div class="configItem"><b>${integration.friendly_name}</b><a class="small">${JSON.stringify(integration.data)}</a></div>`;
    }
  }

  document.getElementById("intergrations").innerHTML = innerHtml;
}

function displaySettings(settings, ui_config) {
  let innerHtml = "<h3>Configuration Settings</h3>";

  innerHtml += `<div class="configItem"><div>Dark mode <input type="checkbox" id="ui_config.darkmode" name="darkmode" ${isChecked(ui_config.darkmode)}></div></div>`;
  innerHtml += `<div class="configItem"><div>Auto brightness <input type="checkbox" id="settings.autobrightness" name="autobrightness" ${isChecked(settings.autobrightness)}></div></div>`;
  innerHtml += `<div class="configItem"><div>Bluetooth area <input type="checkbox" id="settings.bluetootharea" name="bluetootharea" ${isChecked(settings.bluetootharea)}></div></div>`;
  innerHtml += `<div class="configItem"><div>Software Updates <input type="checkbox" id="settings.softwareupdate" name="softwareupdate"></div></div>`;
  innerHtml += `<div class="configItem"><div>Language <select id="settings.language" name="language">`;
  innerHtml += `<option value="en_US">en_US</option>`;
  innerHtml += `<option value="nl_NL">nl_NL</option>`;
  innerHtml += `<option value="de_DE">de_DE</option>`;
  innerHtml += `<option value="jp_JS">jp_JS</option>`;
  innerHtml += `</select></div></div>`;
  innerHtml += `<div class="configItem"><div>Proximity <input type="number" id="settings.proximity" name="proximity"min="10" max="250"></div></div>`;
  innerHtml += `<div class="configItem"><div>Shutdowntime <input type="number" id="settings.shutdowntime" name="shutdowntime"min="0" max="36000"></div></div>`;
  innerHtml += `<div class="configItem"><div>WiFi time <input type="number" id="settings.wifitime" name="wifitime"min="0" max="36000"></div></div>`;

  document.getElementById("settings").innerHTML = innerHtml;
  document.getElementById("settings.language").value = settings.language;
  document.getElementById("settings.proximity").value = settings.proximity;
  document.getElementById("settings.shutdowntime").value = settings.shutdowntime;
  document.getElementById("settings.softwareupdate").checked = settings.softwareupdate;
  document.getElementById("settings.wifitime").value = settings.wifitime;
}

function displayUiConfigGroups(uiConfig, entities) {
  let innerHtml = "<h3>Configuration Groups</h3>";
  const keys = Object.keys(uiConfig.groups);
  let ulArray = [];

  for (let key of keys) {
    const group = uiConfig.groups[key];
    let ulID = `uiConfig.groups.entities.${key}`;
    ulArray.push(ulID);

    innerHtml += `<h4>${group.name}</h4>`;
    innerHtml += `<div class="configItem"><div>Group switch <input type="checkbox" id="groups.${key}.switch" name="groups.${key}.switch" ${isChecked(group.switch)}></div></div>`;

    innerHtml += `<ul id="${ulID}" yioConfig="groups" yioConfigKey="${key}" yioSubConfig="entities" class="dragList">`;
    for (let entity of group.entities) {
      const ent = getEntityById(entities, entity);
      if (ent.friendly_name) {
        innerHtml += `<li class="dragableItem" id="${entity}"><b>${ent.friendly_name}</b> <a class="small">${ent.area}</a></li>`;
      } else {
        innerHtml += `<li class="configItemError"><b> No entity found with UUID: "${entity}" !</b></li>`;
      }
    }
    innerHtml += `</ul>`;
  }

  document.getElementById("ui_config.groups").innerHTML = innerHtml;

  //make list items dragable in ul
  for (ulID of ulArray) {
    makeDragableGroups(ulID);
  }
}

function displayUiConfigPages(uiConfig) {
  let innerHtml = "<h3>Configuration Pages</h3>";
  const keys = Object.keys(uiConfig.pages);
  let ulArray = [];

  for (let key of keys) {
    const page = uiConfig.pages[key];
    let ulID = `uiConfig.pages.groups.${key}`;
    ulArray.push(ulID);

    innerHtml += `<h4>Page: ${page.name}</h4>`;
    innerHtml += `<div class="configItem"><div>Image: ${page.image}</div></div>`;
    innerHtml += `<ul id="${ulID}" yioConfig="pages" yioConfigKey="${key}" yioSubConfig="groups" class="dragList">`;
    for (let group of page.groups) {
      const grp = uiConfig.groups[group];
      if (grp) {
        innerHtml += `<li class="dragableItem" id="${group}"><b>${grp.name}</b></li>`;
      } else {
        innerHtml += `<div class="configItemError"><b> No group found with UUID: "${group}"</b></div>`;
      }
    }
    innerHtml += `</ul>`;
  }
  document.getElementById("ui_config.pages").innerHTML = innerHtml;

  //make list items dragable in ul
  for (ulID of ulArray) {
    makeDragableGroups(ulID);
  }
}

function displayUiConfigProfiles(uiConfig, entities) {
  let innerHtml = "<h3>Configuration Profiles</h3>";
  const keys = Object.keys(uiConfig.profiles);
  let ulArray = [];

  for (let key of keys) {
    const profile = uiConfig.profiles[key];
    let ulID = `uiConfig.profiles.favorites.${key}`;
    ulArray.push(ulID);

    innerHtml += `<h4>Profile: ${profile.name}</h4>`;
    innerHtml += `Favorites:`;
    innerHtml += `<ul id="${ulID}" yioConfig="profiles" yioConfigKey="${key}" yioSubConfig="favorites" class="dragList">`;
    for (let favorite of profile.favorites) {
      const entity = getEntityById(entities, favorite);
      if (entity.friendly_name) {
        innerHtml += `<li class="dragableItem" id="${favorite}"><b>${entity.friendly_name}</b> <a class="small">${entity.area}</a></li>`;
      } else {
        innerHtml += `<div class="configItemError"><b> No entity fount with UUID: "${favorite}" !</b></div>`;
      }
    }
    innerHtml += `</ul>`;
    innerHtml += `Pages:`;
    innerHtml += `<div class="configItem">Assigned pages:`;
    for (let page of profile.pages) {
      if (page === "favorites" || page === "settings") {
        innerHtml += `<div class="configItem"> ${page}</div>`;
      } else {
        const pag = uiConfig.pages[page];
        if (pag) {
          innerHtml += `<div class="configItem">Page: ${pag.name}</div>`;
        } else {
          innerHtml += `<div class="configItemError"><b> No page found with UUID: "${page}"</b></div>`;
        }
      }
    }
    innerHtml += `</div>`;
  }

  document.getElementById("ui_config.profiles").innerHTML = innerHtml;
}

function isChecked(booli) {
  if (booli) {
    return "checked";
  } else {
    return "";
  }
}

function getEntityById(entities, key) {
  let returnEntity = {};
  for (let type of SUPPORTED_ENTITIES) {
    for (let entity of entities[type]) {
      if (entity.entity_id === key) returnEntity = entity;
    }
  }
  return returnEntity;
}

function downloadConfig() {
  let confJson = document.getElementById("configJsonTextBox").value;
  download("config.json", confJson);
}

function download(filename, text) {
  var pom = document.createElement("a");
  pom.setAttribute("href", "data:text/plain;charset=utf-8," + encodeURIComponent(text));
  pom.setAttribute("download", filename);

  if (document.createEvent) {
    var event = document.createEvent("MouseEvents");
    event.initEvent("click", true, true);
    pom.dispatchEvent(event);
  } else {
    pom.click();
  }
}

function arrayMove(arr, oldIndex, newIndex) {
  if (newIndex >= arr.length) {
    var k = newIndex - arr.length + 1;
    while (k--) {
      arr.push(undefined);
    }
  }
  arr.splice(newIndex, 0, arr.splice(oldIndex, 1)[0]);
  return arr; // for testing
}

function makeDragableGroups(id) {
  let x = document.getElementById(id);
  new Sortable(x, {
    group: "words",
    onStart: function(/**Event*/ evt) {
      console.log("onStart.foo:", evt.item);
      console.log(evt.oldIndex);
    },
    onAdd: function(evt) {
      dragableAdd(evt);
    },
    onUpdate: function(evt) {
      dragableMoved(evt);
    },
    onRemove: function(evt) {
      dragableRemove(evt);
    }
  });
}

function dragableMoved(evt) {
  if (evt.from.attributes.yioConfig && evt.from.attributes.yioConfigKey && evt.from.attributes.yioSubConfig) {
    let yioConfig = evt.from.attributes.yioConfig.value;
    let yioConfigKey = evt.from.attributes.yioConfigKey.value;
    let yioSubConfig = evt.from.attributes.yioSubConfig.value;
    let oldIndex = evt.oldIndex;
    let newIndex = evt.newIndex;
    console.log("Item moved");
    console.log(`yioConfig ${yioConfig}`);
    console.log(`yioConfigKey ${yioConfigKey}`);
    console.log(`yioSubConfig ${yioSubConfig}`);
    console.log("From:", oldIndex);
    console.log("To:", newIndex);

    arrayMove(configObj.ui_config[yioConfig][yioConfigKey][yioSubConfig], oldIndex, newIndex);
  }
  parseConfigurationJson();
  setConfig();
}

function dragableAdd(evt) {
  if (evt.to.attributes.yioConfig && evt.to.attributes.yioConfigKey && evt.to.attributes.yioSubConfig) {
    let yioConfigTo = evt.to.attributes.yioConfig.value;
    let yioConfigKeyTo = evt.to.attributes.yioConfigKey.value;
    let yioSubConfigTo = evt.to.attributes.yioSubConfig.value;
    let newIndex = evt.newIndex;
    let itemId = evt.item.id;
    console.log("Item Added");
    console.log(`yioConfigTo ${yioConfigTo}`);
    console.log(`yioConfigKeyTo ${yioConfigKeyTo}`);
    console.log(`yioSubConfigTo ${yioSubConfigTo}`);
    console.log("To:", newIndex);

    configObj.ui_config[yioConfigTo][yioConfigKeyTo][yioSubConfigTo].splice(newIndex, 0, itemId);
  }
  parseConfigurationJson();
  setConfig();
}

function dragableRemove(evt) {
  if (evt.from.attributes.yioConfig && evt.from.attributes.yioConfigKey && evt.from.attributes.yioSubConfig) {
    let yioConfig = evt.from.attributes.yioConfig.value;
    let yioConfigKey = evt.from.attributes.yioConfigKey.value;
    let yioSubConfig = evt.from.attributes.yioSubConfig.value;
    let oldIndex = evt.oldIndex;
    console.log("Item Removed");
    console.log(`yioConfig ${yioConfig}`);
    console.log(`yioConfigKey ${yioConfigKey}`);
    console.log(`yioSubConfig ${yioSubConfig}`);
    console.log("From:", oldIndex);

    configObj.ui_config[yioConfig][yioConfigKey][yioSubConfig].splice(oldIndex, 1);
  }
  parseConfigurationJson();
  setConfig();
}

/////////// Start /////////////////
setActiveUI("None");
let host = window.location.hostname;
if (host === "") {
  host = DEBUG_HOST;
  console.log(`::: Using debug host: "${host}" :::`);
}
wsConnect(`ws://${host}:946`);
