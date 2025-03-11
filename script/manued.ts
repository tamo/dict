// git diff -U0 --no-color --word-diff-regex='[^ /]+[^$]' --word-diff=porcelain 
import { toReadableStream } from 'jsr:@std/io'
import { TextLineStream } from "jsr:@std/streams"
const lines = await toReadableStream(Deno.stdin)
  .pipeThrough(new TextDecoderStream())
  .pipeThrough(new TextLineStream())
  .values()
let opened = false
let output = ""
// let plusLen = 0
// let minusLen = 0
let plus = false
let minus = false
for await (const line of lines) {
  // if (plusLen == 0 /* && minusLen == 0 */) {
    const first6 = line.substring(0, 6)
    switch(first6) {
      case "diff -":
      case "index ":
      case "--- a/":
        continue
      case "+++ b/":
        console.log(`\n\t* ${line.substring(6)}:`)
        continue
      }
  // }
  const first1 = line[0]
  switch(first1) {
    case "@":
      if (/* plusLen || minusLen || */ opened || output) {
        console.error("parse error", { /* plusLen, minusLen, */ opened, output, line })
        break
      } else {
        /*
        const matches = line.match(/^@@ -\d+(,\d+)? \+\d+(,\d+)? @@/)
        const minusStr = matches?.[1]?.substring(1)
        minusLen = minusStr ? Number(minusStr) : 1
        const plusStr = matches?.[2]?.substring(1)
        plusLen = plusStr ? Number(plusStr) : 1
        console.log({line, plusLen, minusLen})
        */
        continue
      }
    case " ":
      plus = true
      minus = true
      if (opened) output += "}"
      opened = false
      output += line.substring(1)
      continue
    case "-":
      minus = true
      output += `{${line.substring(1)}->`
      opened = true
      continue
    case "+":
      plus = true
      if (!opened) output += "{->"
      output += line.substring(1) + "}"
      opened = false
      continue
    case "~":
      /*
      if (plus) plusLen--
      if (minus) minusLen--
      if (plusLen < 0 || minusLen < 0 ) {
        console.error("parse error", { plusLen, minusLen, opened, output, line })
        break
      }
      */
      if (opened) output += "}"
      opened = false
      logWithKindOfChange(output, plus, minus)
      output = ""
      minus = false
      plus = false
      continue
    case "": // EOF
      /*
      if (plusLen || minusLen) {
        console.error("parse error", { plusLen, minusLen, opened, output, line })
        break
      }
      */
      if (opened) output += "}"
      opened = false
      logWithKindOfChange(output, plus, minus)
  }
  break
}

function logWithKindOfChange(output: string, plus: boolean, minus: boolean) {
  let kindOfChange = "Modify."
  if (plus && !minus) {
    kindOfChange = "Add entry."
  } else if (!plus && minus) {
    kindOfChange = "Remove entry."
  }
  console.log(`\n\t${kindOfChange}\n\t${output}`)
}