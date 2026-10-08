class CNpcTorchRewriter extends ITorchRewriter {
    protected function GetTorchSettings(): SLightRewriteTorchLight {
        return theGame.GetLightRewriteSettings().npcTorch;
    }
}
