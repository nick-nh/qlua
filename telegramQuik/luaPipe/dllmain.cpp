// dllmain.cpp : Defines the entry point for the DLL application.
#include "pch.h"

#define LUA_LIB
#define LUA_BUILD_AS_DLL

extern "C" {
#include "./include/lauxlib.h"
#include "./include/lua.h"
}

BOOL APIENTRY DllMain( HMODULE hModule,
                       DWORD  ul_reason_for_call,
                       LPVOID lpReserved
                     )
{
    switch (ul_reason_for_call)
    {
    case DLL_PROCESS_ATTACH:
    case DLL_THREAD_ATTACH:
    case DLL_THREAD_DETACH:
    case DLL_PROCESS_DETACH:
        break;
    }
    return TRUE;
}

static wchar_t* charToWChar(char* text)
{
    size_t size = strlen(text) + 1;
    wchar_t* wText = new wchar_t[size];

    size_t outSize;
    mbstowcs_s(&outSize, wText, size, text, size - 1);
    return wText;
}

static void lua_print(lua_State* LST, const char* text)
{
    lua_getglobal(LST, "print");
    if (lua_isfunction(LST, -1))
    {
        // push function arguments into stack
        lua_pushstring(LST, text);
        lua_pcall(LST, 1, 1, 0);
    }

}

static int forLua_SendTMessage(lua_State* LST)
{
    const char* msg     = lua_tostring(LST, 1);
    const char* pipe_ch = lua_tostring(LST, 2);
    char pipe_name[100];
    sprintf_s(pipe_name, "\\\\.\\pipe\\%s", pipe_ch);
    LPCTSTR lpvMessage    = msg;
    HANDLE hPipe;
    BOOL   fSuccess = FALSE;
    DWORD  cbToWrite, cbWritten, dwMode;
    LPCTSTR lpszPipename = pipe_name;
    char outString[200];

    // Try to open a named pipe; wait for it, if necessary. 

    while (1)
    {
        hPipe = CreateFile(
            lpszPipename,   // pipe name 
            // read and write access 
            GENERIC_WRITE,
            0,              // no sharing 
            NULL,           // default security attributes
            OPEN_EXISTING,  // opens existing pipe 
            0,              // default attributes 
            NULL);          // no template file 

      // Break if the pipe handle is valid. 

        if (hPipe != INVALID_HANDLE_VALUE)
            break;

        // Exit if an error other than ERROR_PIPE_BUSY occurs. 

        if (GetLastError() != ERROR_PIPE_BUSY)
        {
            sprintf_s(outString, "Could not open pipe %s. GLE=%d", pipe_name, GetLastError());
            lua_print(LST, outString);
            return 1;
        }

        // All pipe instances are busy, so wait for 20 seconds. 

        if (!WaitNamedPipe(lpszPipename, 20000))
        {
            lua_print(LST, "Could not open pipe: 20 second wait timed out");
            return 1;
        }
    }

    // Send a message to the pipe server. 

    cbToWrite = (lstrlen(lpvMessage) + 1) * sizeof(TCHAR);
    //sprintf_s(outString, "Write msg to pipe length %d, byte %d", lstrlen(lpvMessage) + 1, cbToWrite);
    //lua_print(LST, outString);

    fSuccess = WriteFile(
        hPipe,                  // pipe handle 
        lpvMessage,             // message 
        cbToWrite,              // message length 
        &cbWritten,             // bytes written 
        NULL);                  // not overlapped 

    if (!fSuccess)
    {
        sprintf_s(outString, "Write msg to pipe failed. GLE=%d", GetLastError());
        lua_print(LST, outString);
        return 1;
    }

    lua_print(LST, "<Message sent to server>");

    CloseHandle(hPipe);
    lua_pushboolean(LST, true);
    return 1;
}

static struct luaL_Reg ls_lib[] = {
    {"SendMessage", forLua_SendTMessage},
    {NULL, NULL}
};

extern "C" LUALIB_API int luaopen_luaPipe(lua_State * LST) {
    lua_newtable(LST);
    luaL_setfuncs(LST, ls_lib, 0);
    lua_pushvalue(LST, -1);
    lua_setglobal(LST, "luaPipe");
    return 0;
}

