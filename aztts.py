#!/usr/bin/env python3

import os
import azure.cognitiveservices.speech as speechsdk
import argparse

SPEECH_KEY = os.environ.get('SPEECH_KEY')
SPEECH_REGION = os.environ.get('SPEECH_REGION')

if not SPEECH_REGION or not SPEECH_KEY:
    print("Check SPEECH_KEY and SPEECH_REGION environment variable!")

speech_config = speechsdk.SpeechConfig(subscription=SPEECH_KEY, region=SPEECH_REGION)
parser = argparse.ArgumentParser(prog='aztts')
parser.add_argument('filename')
parser.add_argument('-o', '--output')
args = parser.parse_args()

speech_config.speech_synthesis_voice_name='en-US-JennyNeural'

speech_synthesizer = speechsdk.SpeechSynthesizer(speech_config=speech_config, audio_config=None)



if not args.output:
    output = args.filename + ".wav"
else:
    output = args.output


with open(args.filename, 'r') as f:
    text = f.read()

speech_synthesis_result = speech_synthesizer.speak_text_async(text).get()

if speech_synthesis_result.reason == speechsdk.ResultReason.SynthesizingAudioCompleted:
    print("Speech synthesized for text [{}]".format(text))
elif speech_synthesis_result.reason == speechsdk.ResultReason.Canceled:
    cancellation_details = speech_synthesis_result.cancellation_details
    print("Speech synthesis canceled: {}".format(cancellation_details.reason))
    if cancellation_details.reason == speechsdk.CancellationReason.Error:
        if cancellation_details.error_details:
            print("Error details: {}".format(cancellation_details.error_details))
            print("Did you set the speech resource key and region values?")

stream = speechsdk.AudioDataStream(speech_synthesis_result)

stream.save_to_wav_file(output)
