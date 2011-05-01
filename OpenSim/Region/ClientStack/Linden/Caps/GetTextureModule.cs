/*
 * Copyright (c) Contributors, http://opensimulator.org/
 * See CONTRIBUTORS.TXT for a full list of copyright holders.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the OpenSimulator Project nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE DEVELOPERS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

using System;
using System.Collections;
using System.Collections.Specialized;
using System.Drawing;
using System.Drawing.Imaging;
using System.Reflection;
using System.IO;
using System.Web;
using log4net;
using Nini.Config;
using Mono.Addins;
using OpenMetaverse;
using OpenMetaverse.StructuredData;
using OpenMetaverse.Imaging;
using OpenSim.Framework;
using OpenSim.Framework.Servers;
using OpenSim.Framework.Servers.HttpServer;
using OpenSim.Region.Framework.Interfaces;
using OpenSim.Region.Framework.Scenes;
using OpenSim.Services.Interfaces;
using Caps = OpenSim.Framework.Capabilities.Caps;
using OpenSim.Capabilities.Handlers;

namespace OpenSim.Region.ClientStack.Linden
{

    [Extension(Path = "/OpenSim/RegionModules", NodeName = "RegionModule")]
    public class GetTextureModule : IRegionModule
    {
        private static readonly ILog m_log =
            LogManager.GetLogger(MethodBase.GetCurrentMethod().DeclaringType);
        private Scene m_scene;
        private IAssetService m_assetService;

        public const string DefaultFormat = "x-j2c";

        // TODO: Change this to a config option
        const string REDIRECT_URL = null;


        #region IRegionModule Members

        public void Initialise(Scene pScene, IConfigSource pSource)
        {
            m_scene = pScene;
        }

        public void PostInitialise()
        {
            m_assetService = m_scene.RequestModuleInterface<IAssetService>();
            m_scene.EventManager.OnRegisterCaps += RegisterCaps;
        }

        public void Close() { }

        public string Name { get { return "GetTextureModule"; } }
        public bool IsSharedModule { get { return false; } }

        public void RegisterCaps(UUID agentID, Caps caps)
        {
            UUID capID = UUID.Random();

            //            m_log.InfoFormat("[GETTEXTURE]: /CAPS/{0} in region {1}", capID, m_scene.RegionInfo.RegionName);
            //caps.RegisterHandler("GetTexture", new StreamHandler("GET", "/CAPS/" + capID, ProcessGetTexture));
            caps.RegisterHandler("GetTexture", new GetTextureHandler("/CAPS/" + capID + "/", m_assetService));
        }

        #endregion
    }
}