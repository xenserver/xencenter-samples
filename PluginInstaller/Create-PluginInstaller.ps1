############################
#
# Note: May need to edit WiX location based on local install
#
# Expected plugin directory structure:
#   $pluginDir
#   |-<org_0>
#   ||-<plugin_0>
#   |||-<plugin_files>
#   ||-<plugin_1>
#   |||-<plugin_files>
#   ||-<plugin_2>
#   |||-<plugin_files>
#   |-<org_1>
#   ||-<plugin_0>
#   |||-<plugin_files>
# etc.
#
# other files below $plugins directory will be included, eg READMEs
#
############################

param(
  $plugins = ("{0}\\_build\\Plugins" -f (get-location)),
  $out = "SamplePlugin.msi",
  $wix = "C:\\Program Files (x86)\\WiX Toolset v3.7\\bin",
  #$loc = "$wix\\WixUI_en-us.wxl",
  #$lib = "$wix\\WixUI.wixlib",
  $ui_ref = "WixUI_Mondo",
  $title = "UserPlugins",
  $manufacturer = "Citrix",
  $description = "XenCenter Plugins",
  $product_version = "1.0.0.0",
  $upgrade_code = "8282b90a-cb51-4c02-a1c1-ecfcff9861bf",
  $product_code = ([System.Guid]::NewGuid().ToString()),
  $version_short = "1.0",
  $icon,
  [switch]$debug,
  [switch]$help
  );

if($help) {
  write-host @"
  
  PluginInstaller Creator:
  
  Create-PluginInstaller [-plugins] <top folder path> [-out] <name of output msi> [-wix <location of wix binaries>] [-loc <location of wix strings>] [-lib <wix ui description library>] [-ui_ref <Wix UI reference>] [-title <name of installation>] [-manufacturer <plugin manufacturer>] [-description <description of plugins>] [-product_version <plugin version>] [-upgrade_code <guid for upgrading>] [-product_code <guid of product>] [-version_short <two number version>] [-icon <path to add/remove programs icon>] [-debug] [-help]

"@
  return;
}
  
#$wix_template = "{0}\\InstallerTemplate.wxs" -f (get-location);

$scriptFolder = Split-Path $MyInvocation.MyCommand.Path -Parent
$scriptFile = "{0}\wix-template.xml" -f $scriptFolder

[string]$template = Get-Content $scriptFile

$plugins_element_xpath = "/*/*/*/*/*/*/*";
$product_element_xpath = "/*/*";
$media_element_xpath = "/*/*/";
$wix_ns = "http://schemas.microsoft.com/wix/2006/wi"
$r = new-object System.Random;
$candle_format = "& '{0}\candle.exe' {1}.wxs -out .\_build\ -nologo";
$light_format = "& '{0}\light.exe' -out {1}.msi {1}.wixobj -ext WixUIExtension -cultures:en-us -nologo"
$wxs_file = ("{0}\{1}.wxs" -f (get-location), ($out).Replace(".msi", ""))

$default_title = "UserPlugins";
$default_title_cab = "UserPluginscab";
$default_manufacturer = "Default Manufacturer";
$default_description = "XenCenter Plugins";
$default_product_version = "<?version-long>";
$default_upgrade_code = "8282b90a-cb51-4c02-a1c1-ecfcff9861bf";
$default_product_code = "67d68e4a-82d2-4a7d-a909-cfce92dbe71a";
$default_version_short = "<?version-short>";

function main {

  function generate-wxs {
  
    function get-folder-location {
      if($plugins -ne $null) { return new-object System.IO.DirectoryInfo $plugins; }
      $plugins = (read-host -prompt "Path of plugins folder");
      return new-object System.IO.DirectoryInfo $plugins;
    }
    
    function get-msiname {
      if($out -ne $null) { return $out; }
      return (read-host -prompt "Output MSI name");
    }
  
    function get-folders([string]$filepath) {
      $folder_paths = @();
      $folders = get-childitem $filepath;
      if ($folders -ne $null ){ 
		foreach($folder in $folders) {
			if($folder.attributes -contains "Directory") {
				$folder_paths += $folder;
			}
		}
	  }	
      return $folder_paths;
    }
    
    function get-files([string]$filepath) {
      $file_paths = @();
      $files = get-childitem $filepath;
      foreach($file in $files) {
        if($file.attributes -notcontains "Directory") {
          $file_paths += $file;
        }
      }
      return $file_paths;
    }
    
    function prep-template {
      $contents = $template
      
      if ( $upgrade_code -match "$" ) { $upgrade_code = Invoke-Expression ($upgrade_code) }
      
      $contents = $contents.Replace($default_title_cab, $title.Replace(" ", "_"));
      $contents = $contents.Replace($default_title, $title);
      $contents = $contents.Replace($default_manufacturer, $manufacturer);
      $contents = $contents.Replace($default_description, $description);
      $contents = $contents.Replace($default_product_version, $product_version);
      $contents = $contents.Replace($default_upgrade_code, $upgrade_code);
      $contents = $contents.Replace($default_product_code, $product_code);
      $contents = $contents.Replace($default_version_short, $version_short);
      Set-Content $wxs_file $contents;
    }
    
    function load-template {
      prep-template;
      $xml_doc = new-object System.Xml.XmlDocument
      $xml_doc.Load($wxs_file);
      return $xml_doc;
    }
    
    function save-template([System.Xml.XmlDocument]$doc, [string]$wxs_path) {
      $doc.Save($wxs_path);
    }
    
    function gen-id([System.Xml.XmlElement]$node, [string]$name) {
      $id = $name.Substring(0, [math]::Min($name.Length, 26) ).Replace("-", "_").Replace(" ", "_") + "_";
      
      for($i=0; $i -le 10; $i++) {
        $id += ([char]$r.Next(97,122)).ToString();
      }
      $node.SetAttribute("Id", $id);
      return $id
    }
    
    function gen-name([System.Xml.XmlElement]$node, [string]$name) {
      #if($name.length -gt 8) { $name = $name.Substring(0,8) }
      $node.SetAttribute("Name", $name.Replace(" ","_"));
    }
    
    function gen-longname([System.Xml.XmlElement]$node, [string]$name) {
      if($name.length -le 8) { return }
      $node.SetAttribute("LongName", $name);
    }
    
    function gen-diskid([System.Xml.XmlElement]$node) {
      $node.SetAttribute("DiskId", "1");
    }
    
    function gen-source([System.Xml.XmlElement]$node, [string]$path) {
      $node.SetAttribute("Source", $path);
    }
    
    function gen-vital([System.Xml.XmlElement]$node) {
      $node.SetAttribute("Vital", "yes");
    }
    
    function add-icon([System.Xml.XmlDocument]$doc, [System.Xml.XmlNode]$parent_node) {
      if($icon -eq $null) {
        return;
      }
      
      $icon_node = [System.Xml.XmlElement]$doc.CreateNode([System.Xml.XmlNodeType]::Element,"Icon",$wix_ns);
      $foo = gen-id $icon_node "icon";
      $icon_node.SetAttribute("SourceFile", $icon);
      $foo = $parent_node.AppendChild($icon_node);
    }
    
    function add-ui-ref([System.Xml.XmlDocument]$doc, [System.Xml.XmlNode]$parent_node) {
      $ui_node = [System.Xml.XmlElement]$doc.CreateNode([System.Xml.XmlNodeType]::Element,"UIRef",$wix_ns);
      $ui_node.SetAttribute("Id", $ui_ref);
      $foo = $parent_node.AppendChild($ui_node);
    }
    
    function add-file([System.Xml.XmlDocument]$doc, [System.Xml.XmlNode]$component_node, [System.IO.FileSystemInfo]$file) {
      $file_node = [System.Xml.XmlElement]$doc.CreateNode([System.Xml.XmlNodeType]::Element,"File",$wix_ns);
      $foo = gen-id $file_node $file.ToString();
      gen-name $file_node $file.ToString();
      #gen-longname $file_node $file.ToString();
      gen-diskid $file_node;
      gen-source $file_node $file.fullname;
      gen-vital $file_node;
      $foo = $component_node.AppendChild($file_node);
    }
    
    function gen-guid([System.Xml.XmlElement]$node) {
      $node.SetAttribute("Guid", [System.Guid]::NewGuid().ToString());
    }
    
    function remove-id([string]$id) {
      if($id.Contains("component_")) {
        return $id.Replace($id.Substring($id.length - 13, 11), "")
      }
      else {
        return $id;
      }
    }
    
    function add-folder([System.Xml.XmlDocument]$doc, [System.Xml.XmlNode]$parent_node, [System.IO.DirectoryInfo]$folder, [int] $depth) {

      if($folder -eq $null) {
        return;
      }

      if($depth -eq 1) {
        $org_name = $folder.ToString();
        $features[$org_name] = @{ "<toplevel>" = @{} };
      }
      elseif($depth -eq 2) {
        $plugin_name = $folder.ToString();
        $features[$org_name].Add($plugin_name,@{});
      }
      
      
      $folder_node = $null;
      if($parent_node -eq $null) {
        $folder_node = $doc.SelectSingleNode($plugins_element_xpath)
      }
      else {
        $folder_node = [System.Xml.XmlElement]$doc.CreateNode([System.Xml.XmlNodeType]::Element,"Directory",$wix_ns);
        $foo = gen-id $folder_node $folder.ToString();
        gen-name $folder_node $folder.ToString();
        #gen-longname $folder_node $folder.ToString();
      }    
      $files = get-files $folder.fullname;
      $id = $null
      if(([System.Object[]]$files).length -gt 0) { # add a new component... we need to keep track of these per plugin
        $component_node = [System.Xml.XmlElement]$doc.CreateNode([System.Xml.XmlNodeType]::Element,"Component",$wix_ns);
        $id = gen-id $component_node ($folder.Name + "component");
        gen-guid $component_node
        foreach($file in $files) {
          add-file $doc $component_node $file
        }
        $foo = $folder_node.AppendChild($component_node)
      }
      
      if($id -ne $null) {
        if($org_name -eq $null) {
          $features["<toplevel>"]["<toplevel>"].Add($id,@{});
        }
        elseif($plugin_name -eq $null) {
          $features[$org_name]["<toplevel>"].Add($id,@{});
        }
        else {
          $features[$org_name][$plugin_name].Add($id,@{});
        }
      }
      $folders = get-folders $folder.fullname;
      if ($folders -ne $null ) {
		  foreach($subfolder in $folders) {
			add-folder $doc $folder_node $subfolder ($depth +1)
		  }
	  }      
      if($parent_node -ne $null) { $foo = $parent_node.AppendChild($folder_node) }
    }
    
    function add-features([System.Xml.XmlDocument]$doc, [System.Xml.XmlNode]$parent_node, [System.Collections.Hashtable]$table, [int]$depth) { 
      if($table -eq @{}) { return }
      foreach($key in $table.Keys) {
        if($depth -gt 2) {
          $component_node = [System.Xml.XmlElement]$doc.CreateNode([System.Xml.XmlNodeType]::Element,"ComponentRef",$wix_ns);
          $component_node.SetAttribute("Id", $key);
          $foo = $parent_node.AppendChild($component_node);
        }
        elseif(!$key.StartsWith("<toplevel>")) {
          $name = (remove-id $key)
          $feature_node = [System.Xml.XmlElement]$doc.CreateNode([System.Xml.XmlNodeType]::Element,"Feature",$wix_ns);
          $foo = gen-id $feature_node $name;
          $feature_node.SetAttribute("Title", $name);
          $feature_node.SetAttribute("Description", "XenCenter plugin provided by {0}" -f $name);
          $feature_node.SetAttribute("Display", "expand");
          $feature_node.SetAttribute("Level", "1");
          $feature_node.SetAttribute("ConfigurableDirectory", "INSTALLDIR");
          $feature_node.SetAttribute("AllowAdvertise", "no");
          $feature_node.SetAttribute("InstallDefault", "local");
          $feature_node.SetAttribute("Absent", "allow");
          add-features $doc $feature_node $table[$key] ($depth + 1);
          $foo = $parent_node.AppendChild($feature_node)
        }
        else {
          add-features $doc $parent_node $table[$key] ($depth + 1);
        }
      }
    }
  
    $features = @{"<toplevel>" = @{"<toplevel>" = @{}}};
    $location = (get-folder-location);
    $doc = [System.Xml.XmlDocument](load-template);
    add-icon $doc ($doc.SelectSingleNode($product_element_xpath));
    add-ui-ref $doc ($doc.SelectSingleNode($product_element_xpath));
    add-folder $doc $null $location 0;
    add-features $doc ($doc.SelectSingleNode($product_element_xpath)) @{"$title" = $features} 0
    save-template $doc $wxs_file;
  }
  
  function build-msi {
    if(![System.IO.Directory]::Exists($wix)) {
      write-host ("Could not find default WiX binaries folder at '{0}'" -f $wix) -foregroundcolor Yellow;
      $wix = read-host "Specify directory containing WiX binaries";
      build-msi;
      return;
    }
    
    $candle_exe = $candle_format -f $wix, $out.Replace(".msi", "")
    invoke-expression $candle_exe
    
    $light_exe = $light_format -f $wix, $out.Replace(".msi", "")
    invoke-expression $light_exe
  }
  
  generate-wxs;
  build-msi;
}

main;