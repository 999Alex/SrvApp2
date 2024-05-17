package Session

import (
	"strings"
	"sync"
)

type Vars struct {
	data     VarData
	OnChange func(aName, aValue string)
}

type VarData struct {
	data map[string]string
	*sync.RWMutex
}

func NewVars() *Vars {
	return &Vars{
		VarData{data: make(map[string]string), RWMutex: &sync.RWMutex{}},
		nil,
	}
}

func (v *Vars) Set(AName string, AValue string) (string, uint) {
	lData := v.data
	lName := strings.ToLower(AName)
	val := ""

	lData.Lock()
	lData.data[lName] = AValue
	lData.Unlock()
	if v.OnChange != nil {
		v.OnChange(lName, AValue)
	}

	return val, 200
}

func (v *Vars) Get(AName string) (string, uint) {
	lData := v.data
	lName := strings.ToLower(AName)

	lData.RLock()
	val := lData.data[lName]
	lData.RUnlock()
	return val, 200
}

func (v *Vars) List() (string, uint) {
	lData := v.data
	lRes := "Variables:\n\r"
	lData.RLock()
	for lVar, lVal := range lData.data {
		lRes = lRes + lVar + " = " + lVal + "\n\r"
	}
	lData.RUnlock()
	return lRes, 250
}
