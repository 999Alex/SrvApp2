package config

import (
	"fmt"
	"log"

	"github.com/go-ini/ini"
)

//type T struct {
//	OutsideKey     string
//	AwesomeSection AwesomeSection
//}

//type AwesomeSection struct {
//	StringValue string
//	IntValue    int
//}

type Config struct {
	Network      NetworkConfig `ini:"Network"`
	Append       AppendConfig
	Main         MainConfig
	Applications []ApplicationConfig
	Users        []UserConfig
}

type NetworkConfig struct {
	PortTCP  uint
	PortSec  uint
	PortHTTP uint
}

type AppendConfig struct {
	Debug int `ini:"debug"`
}

type MainConfig struct {
	Top  int
	Left int
}

type ApplicationConfig struct {
	OpenCmd     string
	OpenMode    uint
	CloseCmd    string
	WorkTimeout uint

	Login    string
	Password string
	PoolMin  uint
}

type UserConfig struct {
	AppIndex int
	Login    string
	Password string
}

func Init() Config {
	//ini.LoadOptions.IgnoreInlineComment=true
	cfg, err := ini.LoadSources(ini.LoadOptions{
		IgnoreInlineComment: true},
		"SrvApp.ini")

	//cfg, err := ini.Load("SrvApp.ini")
	if err != nil {
		log.Fatal("Не удалось прочитать файл настроек ! ", err)
	}

	config := Config{}
	cfg.MapTo(&config)
	cfg.SectionStrings()

	for si := 0; si < 10; si++ {
		sn := fmt.Sprintf("%d", si)
		section, err := cfg.GetSection("App_" + sn)
		if err != nil {
			continue
		}
		var lApp ApplicationConfig
		lApp.OpenCmd = section.Key("OpenCmd").String()
		lApp.OpenMode, _ = section.Key("OpenMode").Uint()
		lApp.CloseCmd = section.Key("CloseCmd").String()
		lApp.WorkTimeout, _ = section.Key("WorkTimeout").Uint()
		lApp.PoolMin, _ = section.Key("PoolMin").Uint()
		lApp.Login = section.Key("Login").String()
		lApp.Password = section.Key("Password").String()

		config.Applications = append(config.Applications, lApp)
		//log.Printf("OutsideKey: %s", k)
	}
	for si := 0; si < 10; si++ {
		sn := fmt.Sprintf("%d", si)
		section, err := cfg.GetSection("User_" + sn)
		if err != nil {
			continue
		}
		var lUser UserConfig
		lUser.Login = section.Key("Login").String()
		lUser.Password = section.Key("Password").String()
		lUser.AppIndex, _ = section.Key("AppIndex").Int()
		config.Users = append(config.Users, lUser)
	}
	return config
}
