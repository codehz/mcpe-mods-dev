import macros

proc mcpelauncher_hook*(a: pointer, b: pointer, c: pointer) {. importc .}

macro hook*(head, body: untyped): untyped =
  head.expectKind(nnkStrLit)
  let linkName = head.strVal
  body.expectLen(1)
  let procDef = body[0]
  var exported = false
  var funcName = "".toNimIdent
  procDef[0].expectKind(nnkIdent)
  if procDef[0].kind == nnkPostfix:
    exported = true
    funcName = procDef[0][1].ident
  else:
    funcName = procDef[0].ident
  let params = procDef[3]
  let pragmas = procDef[4]
  var fnBody = procDef[6]

  let reflIdent = ident($funcName & "Refl")
  let origIdent = ident($funcName & "Orig")
  let realIdent = newIdentNode(funcName)

  var defReal = realIdent
  if exported:
    defReal = nnkPostfix.newTree(
      ident("*"),
      realIdent
    )

  if pragmas.kind == nnkPragma and pragmas.len == 1 and $pragmas[0].ident == "refl":
    var callNode = nnkCall.newTree(reflIdent)
    var skip = true
    for param in params:
      if skip:
        skip = false
        continue
      callNode = callNode.add(param[0])
    fnBody = fnBody.add(callNode)

  nnkStmtList.newTree(
    nnkVarSection.newTree(
      nnkIdentDefs.newTree(
        reflIdent,
        nnkPar.newTree(
          nnkProcTy.newTree(
            params,
            nnkPragma.newTree(
              newIdentNode("cdecl")
            )
          )
        ),
        newNilLit()
      )
    ),
    nnkProcDef.newTree(
      origIdent,
      newEmptyNode(),
      newEmptyNode(),
      params,
      nnkPragma.newTree(
        nnkExprColonExpr.newTree(
          newIdentNode("importc"),
          newLit(linkName)
        )
      ),
      newEmptyNode(),
      newEmptyNode()
    ),
    nnkProcDef.newTree(
      defReal,
      newEmptyNode(),
      newEmptyNode(),
      params,
      nnkPragma.newTree(
        newIdentNode("exportc")
      ),
      newEmptyNode(),
      fnBody
    ),
    nnkCall.newTree(
      newIdentNode("mcpelauncher_hook"),
      origIdent,
      realIdent,
      nnkCall.newTree(
        newIdentNode("addr"),
        reflIdent
      )
    )
  )
