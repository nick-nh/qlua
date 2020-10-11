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

static HANDLE get_pipe(lua_State* LST, char* pipe_name)
{
    HANDLE hPipe;
    LPCTSTR lpszPipename = pipe_name;
    char outString[200];

    // Try to open a named pipe; wait for it, if necessary. 

    while (1)
    {
        hPipe = CreateFile(
            lpszPipename,   // pipe name 
            // read and write access 
            GENERIC_READ |  // read and write access 
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
            return NULL;
        }

        // All pipe instances are busy, so wait for 20 seconds. 

        if (!WaitNamedPipe(lpszPipename, 20000))
        {
            lua_print(LST, "Could not open pipe: 20 second wait timed out");
            return NULL;
        }
    }

    return hPipe;

}

static BOOLEAN SendMessageToPipe(lua_State* LST, HANDLE hPipe, LPCTSTR lpvMessage, DWORD  cbToWrite)
{
    BOOL   fSuccess = FALSE;
    DWORD  cbWritten;
    char outString[200];

    // Send a message to the pipe server. 

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
        return NULL;
    }

    return TRUE;
}

static int forLua_SendTMessage(lua_State* LST)
{
    const char* msg     = lua_tostring(LST, 1);
    const char* pipe_ch = lua_tostring(LST, 2);
    char pipe_name[100];
    sprintf_s(pipe_name, "\\\\.\\pipe\\%s", pipe_ch);

    LPCTSTR lpvMessage    = msg;

    char outString[200];

    // Try to open a named pipe; wait for it, if necessary. 
    HANDLE hPipe = get_pipe(LST, pipe_name);

    if (hPipe == NULL)
    {
        lua_pushboolean(LST, FALSE);
        return NULL;
    }

    if (!SendMessageToPipe(LST, hPipe, lpvMessage, (lstrlen(lpvMessage) + 1) * sizeof(TCHAR)))
    {
        lua_pushboolean(LST, false);
        return 1;
    }

    lua_print(LST, "<Message was sent to server>");

    CloseHandle(hPipe);
    lua_pushboolean(LST, true);
    return 1;
}

static int forLua_GetIncomeMessages(lua_State* LST)
{
    const char* pipe_ch = lua_tostring(LST, 1);
    char pipe_name[100];
    sprintf_s(pipe_name, "\\\\.\\pipe\\%s", pipe_ch);

    LPCTSTR lpvMessage    = TEXT("GetIncomeMessages()");
    BOOL   fSuccess = FALSE;
    TCHAR  chBuf[BUFSIZE]; 
    DWORD  cbRead, cbToWrite, cbWritten, dwMode;
    TCHAR*  getMsg;
    getMsg = new TCHAR[BUFSIZE];

    char outString[200];

    // Try to open a named pipe; wait for it, if necessary. 
    HANDLE hPipe = get_pipe(LST, pipe_name);

    if (hPipe == NULL)
    {
        lua_pushboolean(LST, FALSE);
        return NULL;
    }

    //char buffer[sizeof(lpvMessage)];
    //memcpy(buffer, &lpvMessage, sizeof(lpvMessage));

    if (!SendMessageToPipe(LST, hPipe, lpvMessage, (lstrlen(lpvMessage) + 1) * sizeof(TCHAR)))
    {
        lua_pushboolean(LST, false);
        return 1;
    }

    //int iteration = 0;
    //TCHAR* tmp;
    //tmp = new TCHAR[BUFSIZE];

    do
    {
        // Read from the pipe. 
        //if (iteration > 0)
        //{
        //    TCHAR  tmp[sizeof(getMsg)];
        //    memcpy(tmp, &getMsg, sizeof(getMsg));

        //    getMsg = new TCHAR[sizeof(tmp) + BUFSIZE];
        //    memcpy(getMsg, &tmp, sizeof(tmp));
        //    delete[] tmp;

        //};

        fSuccess = ReadFile(
            hPipe,    // pipe handle 
            chBuf,    // buffer to receive reply 
            BUFSIZE * sizeof(TCHAR),  // size of buffer 
            &cbRead,  // number of bytes read 
            NULL);    // not overlapped 
            
        //memcpy(getMsg, &chBuf, sizeof(chBuf));
        //chBuf[cbRead] = '\0';

        if (!fSuccess && GetLastError() != ERROR_MORE_DATA)
            break;

    } while (!fSuccess);  // repeat loop if ERROR_MORE_DATA 

    if (!fSuccess)
    {
        sprintf_s(outString, "Read msg from pipe failed. GLE=%d", GetLastError());
        lua_print(LST, outString);
        return NULL;
    }

    CloseHandle(hPipe);
    lua_pushstring(LST, chBuf);
    return 1;
}

static struct luaL_Reg ls_lib[] = {
    {"SendMessage", forLua_SendTMessage},
    {"GetIncomeMessages", forLua_GetIncomeMessages},
    {NULL, NULL}
};

extern "C" LUALIB_API int luaopen_luaPipe(lua_State * LST) {
    lua_newtable(LST);
    luaL_setfuncs(LST, ls_lib, 0);
    lua_pushvalue(LST, -1);
    lua_setglobal(LST, "luaPipe");
    return 0;
}

